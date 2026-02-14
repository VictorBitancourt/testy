class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    @users = User.order(:username)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)

    if @user.save
      redirect_to users_path, notice: "User created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_update_params)
      redirect_to users_path, notice: "Password reset successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == Current.user
      redirect_to users_path, alert: "You cannot delete yourself."
    else
      @user.destroy
      redirect_to users_path, notice: "User removed successfully!"
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_create_params
      params.require(:user).permit(:username, :password, :password_confirmation, :role)
    end

    def user_update_params
      params.require(:user).permit(:password, :password_confirmation)
    end
end
