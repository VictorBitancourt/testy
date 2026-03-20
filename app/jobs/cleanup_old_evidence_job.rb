class CleanupOldEvidenceJob < ApplicationJob
  queue_as :cleanup

  OLD_EVIDENCE_DAYS = 90

  def perform
    cleanup_old_evidence_files
  end

  private

  def cleanup_old_evidence_files
    cutoff_date = OLD_EVIDENCE_DAYS.days.ago

    test_scenarios = TestScenario
      .where("test_scenarios.created_at < ?", cutoff_date)
      .where.not(status: "failed")

    deleted_count = 0

    test_scenarios.find_each do |scenario|
      next unless scenario.evidence_files.attached?

      scenario.evidence_files.purge
      deleted_count += 1
    end

    Rails.logger.info("[CleanupOldEvidenceJob] Deleted #{deleted_count} evidence files older than #{OLD_EVIDENCE_DAYS} days")
  end
end
