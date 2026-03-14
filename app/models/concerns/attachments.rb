module Attachments
  extend ActiveSupport::Concern

  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp application/pdf].freeze
  MAX_FILE_SIZE = 10.megabytes

  included do
    has_many_attached :evidence_files

    validate :acceptable_evidence_files, if: -> { evidence_files.any? }
  end

  class_methods do
    def allowed_content_types
      ALLOWED_CONTENT_TYPES
    end

    def max_file_size
      MAX_FILE_SIZE
    end
  end

  def has_evidence?
    evidence_files.attached?
  end

  def evidence_count
    evidence_files.count
  end

  private
    def acceptable_evidence_files
      evidence_files.each do |file|
        unless file.blob.content_type.in?(ALLOWED_CONTENT_TYPES)
          errors.add(:evidence_files, "must be an image (PNG, JPEG, GIF, WebP) or PDF")
        end

        if file.blob.byte_size > MAX_FILE_SIZE
          errors.add(:evidence_files, "must be less than #{MAX_FILE_SIZE / 1.megabyte} MB")
        end
      end
    end
end
