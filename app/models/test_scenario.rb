class TestScenario < ApplicationRecord
  belongs_to :test_plan
  has_many_attached :evidence_files

  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending approved failed] }

  after_initialize :set_default_status, if: :new_record?
  before_create :set_default_position

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def set_default_position
    self.position ||= (test_plan.test_scenarios.maximum(:position) || -1) + 1
  end
end