module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_token
  end

  private

  def authenticate_api_token
    token = extract_bearer_token
    api_token = ApiToken.find_by_raw_token(token)

    if api_token
      api_token.touch_last_used
      @current_api_user = api_token.user
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_api_user
    @current_api_user
  end

  def authorize_owner_or_admin!(record)
    unless current_api_user.admin? || record.user == current_api_user
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def authorize_plan_owner_or_admin!(plan)
    unless current_api_user.admin? || plan.user == current_api_user
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def extract_bearer_token
    header = request.headers["Authorization"]
    header&.match(/\ABearer\s+(.+)\z/)&.captures&.first
  end
end
