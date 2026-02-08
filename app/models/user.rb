class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :test_plans, dependent: :nullify

  normalizes :username, with: ->(u) { u.strip.downcase }

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 50 },
                       format: { with: /\A[a-zA-Z0-9_\-]+\z/ }

  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, inclusion: { in: %w[admin user] }

  def admin?
    role == "admin"
  end
end
