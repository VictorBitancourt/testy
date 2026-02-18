class TestPlan < ApplicationRecord
  belongs_to :user
  has_many :test_scenarios, -> { order(position: :asc) }, dependent: :destroy
  has_many :test_plan_tags, dependent: :destroy
  has_many :tags, through: :test_plan_tags

  validates :name, presence: true
  validates :qa_name, presence: true

  scope :search, ->(query) {
    left_joins(:tags)
      .where("test_plans.name LIKE :q OR test_plans.qa_name LIKE :q OR tags.name LIKE :q", q: "%#{sanitize_sql_like(query)}%")
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
    AiScenarioGenerator.new(self).call(prompt)
  end
end
