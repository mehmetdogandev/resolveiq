module Authentication
  extend ActiveSupport::Concern

  COOKIE_NAME = :resolveiq_session

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    resume_session || render(json: { error: "Oturum açmanız gerekiyor", code: "unauthenticated" }, status: :unauthorized)
  end

  def resume_session
    Current.session ||= Session.find_by_token(cookies[COOKIE_NAME])&.tap(&:touch_last_seen!)
  end

  def start_new_session_for(user)
    session, token = Session.start!(user, request)
    cookies[COOKIE_NAME] = cookie_options.merge(value: token, expires: session.expires_at)
    Current.session = session
  end

  def terminate_session
    Current.session&.destroy
    Current.session = nil
    cookies.delete(COOKIE_NAME, **cookie_options)
  end

  def cookie_options
    { httponly: true, secure: Rails.env.production?, same_site: :lax, path: "/" }
  end

  def current_user
    Current.user
  end
end
