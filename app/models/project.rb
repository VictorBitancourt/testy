# A workspace for one application under test: its test plans, bugs and bug analyses.
class Project < ApplicationRecord
  belongs_to :user, optional: true
  has_many :test_plans, dependent: :destroy
  has_many :bugs, dependent: :destroy
  has_many :bug_analyses, dependent: :destroy

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 80 }
end
