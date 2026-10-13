module Api
  module V1
    class SessionsController < BaseController
      allow_unauthenticated_access only: :create
      rate_limit to: 10, within: 1.minute, only: :create,
                 with: -> { render_error("Çok fazla giriş denemesi. Bir dakika sonra tekrar deneyin.", status: :too_many_requests, code: "rate_limited") }

      def show
        render json: { user: current_user.me_json }
      end

      def create
        user = User.find_by(email: params.require(:email).to_s.strip.downcase)
        if user&.authenticate(params.require(:password).to_s)
          start_new_session_for(user)
          AuditLog.record!(actor: user, action: "session.login", target: user, metadata: { ip: request.remote_ip })
          render json: { user: user.me_json }, status: :created
        else
          render_error("E-posta veya parola hatalı", status: :unauthorized, code: "invalid_credentials")
        end
      end

      def destroy
        terminate_session
        head :no_content
      end
    end
  end
end
