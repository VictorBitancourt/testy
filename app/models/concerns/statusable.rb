module Statusable
  extend ActiveSupport::Concern

  included do
    validates :status, inclusion: { in: %w[pending approved failed] }
    after_initialize :set_default_status, if: :new_record?
  end

  class_methods do
    def pending
      where(status: "pending")
    end

    def approved
      where(status: "approved")
    end

    def failed
      where(status: "failed")
    end
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def failed?
    status == "failed"
  end

  def approve!
    update!(status: "approved")
  end

  def fail!
    update!(status: "failed")
  end

  def reset!
    update!(status: "pending")
  end

  private
    def set_default_status
      self.status ||= "pending"
    end
end
