module Roleable
  extend ActiveSupport::Concern

  included do
    validates :role, inclusion: { in: %w[admin user] }
  end

  def admin?
    role == "admin"
  end
end
