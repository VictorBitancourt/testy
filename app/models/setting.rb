# App-wide options, kept in a single row.
class Setting < ApplicationRecord
  REPORT_LOGO_CONTENT_TYPES = %w[image/jpeg image/png].freeze

  has_one_attached :report_logo
  encrypts :gemini_api_key, :openai_api_key, :anthropic_api_key

  validates :ai_provider, inclusion: { in: -> { AiProviders::ALL.keys } }, allow_blank: true
  validate :acceptable_report_logo, if: -> { report_logo.attached? }

  # A model name belongs to one provider: switching providers falls back to the new one's default.
  before_save -> { self.ai_model = nil }, if: -> { ai_provider_changed? && !ai_model_changed? }

  def self.current
    first_or_create!
  end

  def api_key_for(provider)
    public_send("#{provider}_api_key") if respond_to?("#{provider}_api_key")
  end

  private
    def acceptable_report_logo
      unless report_logo.blob.content_type.in?(REPORT_LOGO_CONTENT_TYPES)
        errors.add(:report_logo, :invalid_content_type)
      end

      if report_logo.blob.byte_size > Attachments::MAX_FILE_SIZE
        errors.add(:report_logo, :too_large, max: Attachments::MAX_FILE_SIZE / 1.megabyte)
      end
    end
end
