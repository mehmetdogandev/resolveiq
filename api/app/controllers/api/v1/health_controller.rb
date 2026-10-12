module Api
  module V1
    class HealthController < BaseController
      allow_unauthenticated_access

      def show
        result = HealthCheck.call
        render json: result.payload, status: result.healthy ? :ok : :service_unavailable
      end
    end
  end
end
