module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_token, only: :login

      RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

      rate_limit to: 5, within: 1.minute, only: :login, store: RATE_LIMIT_STORE, with: -> {
        render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests
      }

      def login
        user = User.authenticate_by(username: params[:username], password: params[:password])

        if user
          token = user.api_tokens.create!(name: params[:token_name])
          render json: {
            token: token.raw_token,
            user: { id: user.id, username: user.username, role: user.role }
          }, status: :created
        else
          render json: { error: "Invalid username or password" }, status: :unauthorized
        end
      end

      def logout
        raw = extract_bearer_token
        token = ApiToken.find_by_raw_token(raw)

        if token&.destroy
          render json: { message: "Logged out successfully" }, status: :ok
        else
          render json: { error: "Token not found" }, status: :not_found
        end
      end
    end
  end
end
