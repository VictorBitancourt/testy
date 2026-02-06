class User < ApplicationRecord
  include Roleable

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :test_plans, dependent: :nullify
  has_many :bugs, dependent: :nullify

  normalizes :username, with: ->(u) { u.strip.downcase }

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 50 },
                       format: { with: /\A[a-zA-Z0-9_\-]+\z/ }

  validates :password, length: { minimum: 8 }, if: -> { password.present? }
end
