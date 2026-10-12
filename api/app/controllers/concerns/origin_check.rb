# CSRF defence for cookie-authenticated requests: state-changing requests must
# come from an allowed frontend origin. Requests without an Origin header
# (curl, server-to-server) are allowed because browsers always send it on
# cross-site mutations.
module OriginCheck
  extend ActiveSupport::Concern

  included do
    before_action :verify_request_origin
  end

  private

  def verify_request_origin
    return if request.get? || request.head? || request.options?

    origin = request.headers["Origin"]
    return if origin.blank?
    return if Rails.application.config.x.frontend_origins.include?(origin)

    render json: { error: "İzin verilmeyen kaynak (origin)", code: "bad_origin" }, status: :forbidden
  end
end
