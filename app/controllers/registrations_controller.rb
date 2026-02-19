class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_no_users

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = "admin"

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t('controllers.registrations.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.require(:user).permit(:username, :password, :password_confirmation)
    end

    def require_no_users
      if User.any?
        redirect_to root_path
      end
    end
end
