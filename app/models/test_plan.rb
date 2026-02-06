class TestPlan < ApplicationRecord
  has_many :test_scenarios, dependent: :destroy

  validates :name, presence: true
  validates :qa_name, presence: true

  scope :nao_iniciado, -> { where.not(id: TestScenario.select(:test_plan_id)) }

  scope :aprovado, -> {
    where(id: TestScenario.select(:test_plan_id)
      .group(:test_plan_id)
      .having("COUNT(*) = COUNT(CASE WHEN status = 'approved' THEN 1 END)"))
  }

  scope :reprovado, -> { where(id: TestScenario.where(status: "failed").select(:test_plan_id)) }

  scope :em_andamento, -> {
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
      "nao_iniciado"
    elsif test_scenarios.any? { |s| s.status == "failed" }
      "reprovado"
    elsif test_scenarios.all? { |s| s.status == "approved" }
      "aprovado"
    else
      "em_andamento"
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
end