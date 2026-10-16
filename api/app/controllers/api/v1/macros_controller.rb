module Api
  module V1
    class MacrosController < BaseController
      def index
        render json: { macros: Macro.active.map(&:as_api_json) }
      end
    end
  end
end
