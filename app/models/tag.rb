class Tag < ApplicationRecord
  has_many :test_plan_tags, dependent: :destroy
  has_many :test_plans, through: :test_plan_tags

  validates :name, presence: true, uniqueness: true

  normalizes :name, with: ->(name) { name.strip.downcase }

  scope :search, ->(query) { where("name LIKE ?", "%#{sanitize_sql_like(query)}%") }
end
