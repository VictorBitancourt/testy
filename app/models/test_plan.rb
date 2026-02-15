require "net/http"

class TestPlan < ApplicationRecord
  belongs_to :user
  has_many :test_scenarios, -> { order(position: :asc) }, dependent: :destroy
  has_many :test_plan_tags, dependent: :destroy
  has_many :tags, through: :test_plan_tags

  validates :name, presence: true
  validates :qa_name, presence: true

  scope :search, ->(query) {
    left_joins(:tags)
      .where("test_plans.name LIKE :q OR test_plans.qa_name LIKE :q OR tags.name LIKE :q", q: "%#{query}%")
      .distinct
  }

  scope :tagged_with, ->(name) { joins(:tags).where(tags: { name: name }) }

  def tag_list
    tags.pluck(:name).join(", ")
  end

  def tag_list=(names)
    self.tags = names.split(",").map(&:strip).reject(&:blank?).uniq.map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end

  scope :not_started, -> { where.not(id: TestScenario.select(:test_plan_id)) }

  scope :approved_plans, -> {
    where(id: TestScenario.select(:test_plan_id)
      .group(:test_plan_id)
      .having("COUNT(*) = COUNT(CASE WHEN status = 'approved' THEN 1 END)"))
  }

  scope :failed_plans, -> { where(id: TestScenario.where(status: "failed").select(:test_plan_id)) }

  scope :in_progress, -> {
    has_scenarios = TestScenario.select(:test_plan_id)
    has_failed = TestScenario.where(status: "failed").select(:test_plan_id)
    all_approved = TestScenario.select(:test_plan_id)
      .group(:test_plan_id)
      .having("COUNT(*) = COUNT(CASE WHEN status = 'approved' THEN 1 END)")
    where(id: has_scenarios).where.not(id: has_failed).where.not(id: all_approved)
  }

  scope :created_from, ->(date) { where("created_at >= ?", date.to_date.beginning_of_day) }
  scope :created_until, ->(date) { where("created_at <= ?", date.to_date.end_of_day) }

  def derived_status
    if test_scenarios.empty?
      "not_started"
    elsif test_scenarios.any? { |s| s.status == "failed" }
      "failed"
    elsif test_scenarios.all? { |s| s.status == "approved" }
      "approved"
    else
      "in_progress"
    end
  end

  def all_scenarios_approved?
    test_scenarios.any? && test_scenarios.all? { |scenario| scenario.status == 'approved' }
  end

  def total_scenarios
    test_scenarios.count
  end

  def approved_scenarios
    test_scenarios.where(status: 'approved').count
  end

  def generate_scenarios_with_ai(prompt)
    return { success: false, error: "Please enter a feature description." } if prompt.blank?

    api_key = ENV["GEMINI_API_KEY"]
    return { success: false, error: "GEMINI_API_KEY is not configured." } if api_key.blank?

    gemini_prompt = build_gemini_prompt(prompt)
    response_body = call_gemini_api(api_key, gemini_prompt)
    data = parse_gemini_response(response_body)
    scenarios = create_scenarios_from_ai(data)

    { success: true, scenarios: scenarios }
  rescue JSON::ParserError
    { success: false, error: "Failed to parse AI response. Please try again." }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { success: false, error: "AI service timed out. Please try again." }
  rescue StandardError => e
    Rails.logger.error("[Gemini AI] #{e.class}: #{e.message}")
    { success: false, error: "AI generation failed: #{e.message}" }
  end

  private

  def build_gemini_prompt(description)
    <<~PROMPT
      You are a senior QA engineer. Given the feature description below, generate test scenarios using these techniques:
      - Happy path
      - Alternative/negative paths
      - Boundary value analysis
      - Equivalence partitioning
      - Edge cases

      Rules:
      - Return ONLY a JSON array, no extra text
      - Each object must have keys: "title", "given", "when_step", "then_step"
      - Each step must be a single sentence (no AND)
      - Match the language of the input description
      - Generate between 5 and 15 scenarios

      Feature description:
      #{description}
    PROMPT
  end

  def call_gemini_api(api_key, prompt)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{api_key}")

    body = {
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: {
        responseMimeType: "application/json"
      }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    http.open_timeout = 15
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Gemini API returned #{response.code}: #{response.body}"
    end

    response.body
  end

  def parse_gemini_response(body)
    parsed = JSON.parse(body)
    text = parsed.dig("candidates", 0, "content", "parts", 0, "text").to_s

    # Strip markdown fences if present
    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "").strip

    data = JSON.parse(text)
    raise JSON::ParserError, "Expected an array" unless data.is_a?(Array)

    data
  end

  def create_scenarios_from_ai(data)
    data.map do |item|
      test_scenarios.create!(
        title: item["title"].to_s.strip,
        given: item["given"].to_s.strip,
        when_step: item["when_step"].to_s.strip,
        then_step: item["then_step"].to_s.strip
      )
    end
  end
end