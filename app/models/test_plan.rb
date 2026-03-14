class TestPlan < ApplicationRecord
  include Taggable
  include Searchable

  belongs_to :user, optional: true
  has_many :test_scenarios, -> { order(position: :asc) }, dependent: :destroy

  validates :name, presence: true
  validates :qa_name, presence: true

  def self.searchable_extra_conditions(_query_pattern)
    [ "tags.name LIKE :q" ]
  end

  def self.searchable_joins_scope
    left_joins(:tags)
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

  scope :created_from, ->(date) { where("created_at >= ?", date.to_date.beginning_of_day) if date.present? }
  scope :created_until, ->(date) { where("created_at <= ?", date.to_date.end_of_day) if date.present? }

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
    test_scenarios.any? && test_scenarios.all? { |scenario| scenario.status == "approved" }
  end

  def total_scenarios
    if test_scenarios.loaded?
      test_scenarios.size
    else
      test_scenarios.count
    end
  end

  def approved_scenarios
    if test_scenarios.loaded?
      test_scenarios.count { |s| s.status == "approved" }
    else
      test_scenarios.where(status: "approved").count
    end
  end

  def generate_scenarios_with_ai(prompt)
    AiScenarioGenerator.new(self).call(prompt)
  end
end
