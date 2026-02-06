class TestScenario < ApplicationRecord
  include Statusable
  include Positionable
  include Attachments

  belongs_to :test_plan
  belongs_to :bug, optional: true

  validates :title, :given, :when_step, :then_step, presence: true
  validate :cannot_approve_with_bug

  private

  def cannot_approve_with_bug
    if status == "approved" && bug_id.present?
      errors.add(:status, :cannot_approve_with_bug)
    end
  end
end
