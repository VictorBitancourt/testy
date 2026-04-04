module Statusable
  extend ActiveSupport::Concern

  included do
    validates :status, inclusion: { in: %w[pending approved failed] }
    after_initialize :set_default_status, if: :new_record?
  end

  private
    def set_default_status
      self.status ||= "pending"
    end
end
