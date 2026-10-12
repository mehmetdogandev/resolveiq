module Api
  module V1
    class ReportsController < BaseController
      def show
        render json: ReportsMetrics.new.as_json
      end
    end
  end
end
