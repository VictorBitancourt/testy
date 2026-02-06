class Bug < ApplicationRecord
  include Attachments

  belongs_to :user
  has_many :test_scenarios

  validates :title, presence: true
  validates :description, presence: true
  validates :status, inclusion: { in: %w[open resolved] }

  scope :open_bugs, -> { where(status: "open") }
  scope :resolved, -> { where(status: "resolved") }
  scope :by_feature, ->(tag) { where(feature_tag: tag) if tag.present? }
  scope :by_cause, ->(tag) { where(cause_tag: tag) if tag.present? }
  scope :search, ->(q) {
    next none unless q.present?
    stripped = q.to_s.gsub(/\A#/, "").strip
    if stripped.match?(/\A\d+\z/)
      where("bugs.id = :id OR title LIKE :q OR description LIKE :q", id: stripped.to_i, q: "%#{sanitize_sql_like(q)}%")
    else
      where("title LIKE :q OR description LIKE :q", q: "%#{sanitize_sql_like(q)}%")
    end
  }
  scope :created_from, ->(date) { where("bugs.created_at >= ?", date.to_date.beginning_of_day) if date.present? }
  scope :created_until, ->(date) { where("bugs.created_at <= ?", date.to_date.end_of_day) if date.present? }

  after_initialize :set_default_status, if: :new_record?

  def display_name = "##{id} - #{title}"
  def resolved? = status == "resolved"
  def open? = status == "open"

  private
    def set_default_status
      self.status ||= "open"
    end
end
