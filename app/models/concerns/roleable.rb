module Roleable
  extend ActiveSupport::Concern

  included do
    validates :role, inclusion: { in: %w[admin user] }
  end

  class_methods do
    def admins
      where(role: "admin")
    end

    def regular_users
      where(role: "user")
    end
  end

  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end

  def make_admin!
    update!(role: "admin")
  end

  def make_user!
    update!(role: "user")
  end
end
