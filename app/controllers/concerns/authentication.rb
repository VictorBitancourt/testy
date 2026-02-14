module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :current_user_admin?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      return redirect_to_setup if User.none?
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      if cookies.signed[:session_id]
        Session.find_by(id: cookies.signed[:session_id])
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def redirect_to_setup
      if request.path != new_registration_path
        redirect_to new_registration_path
      end
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |s|
        Current.session = s
        cookies.signed.permanent[:session_id] = { value: s.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def current_user_admin?
      Current.user&.admin?
    end

    def require_admin
      unless current_user_admin?
        redirect_to root_path, alert: "Access restricted to administrators."
      end
    end

    def authorize_plan_owner_or_admin(plan)
      unless current_user_admin? || plan.user == Current.user
        redirect_to root_path, alert: "You do not have permission for this action."
      end
    end
end
