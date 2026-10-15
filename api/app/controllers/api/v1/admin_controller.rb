module Api
  module V1
    # Render's free plan has no shell, so the demo dataset can be rebuilt through
    # this token-protected endpoint. Disabled unless ADMIN_TOKEN is configured.
    class AdminController < BaseController
      allow_unauthenticated_access
      skip_before_action :verify_request_origin

      def demo_reset
        expected = ENV["ADMIN_TOKEN"].to_s
        provided = request.headers["X-Admin-Token"].to_s
        unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided)
          return render_error("Yetkisiz", status: :unauthorized, code: "unauthorized")
        end

        render json: DemoSeed.reset!
      end
    end
  end
end
