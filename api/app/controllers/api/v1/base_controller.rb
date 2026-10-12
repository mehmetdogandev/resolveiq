module Api
  module V1
    class BaseController < ApplicationController
      include OriginCheck
      include Authentication
      include Authorization

      PER_PAGE = 25

      rescue_from StandardError, with: :render_internal_error
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ArgumentError, with: :render_bad_request
      rescue_from Authorization::Forbidden, with: :render_forbidden
      rescue_from Llm::Unavailable, with: :render_ai_unavailable
      rescue_from Llm::Error, with: :render_ai_error

      private

      def render_error(message, status:, details: nil, code: nil)
        body = { error: message }
        body[:code] = code if code
        body[:details] = details if details
        render json: body, status: status
      end

      def render_not_found(_error = nil)
        render_error("Kayıt bulunamadı", status: :not_found, code: "not_found")
      end

      def render_record_invalid(error)
        render_validation(error.record)
      end

      def render_validation(record)
        render_error("Doğrulama hatası", status: :unprocessable_content, code: "validation_failed",
                     details: record.errors.to_hash(true))
      end

      def render_bad_request(error)
        render_error(error.message.presence || "Geçersiz istek", status: :bad_request, code: "bad_request")
      end

      def render_forbidden(error)
        render_error(error.message.presence || "Bu işlem için yetkiniz yok", status: :forbidden, code: "forbidden")
      end

      def render_ai_unavailable(error)
        render_error(error.message, status: :service_unavailable, code: "ai_unavailable")
      end

      def render_ai_error(error)
        render_error("AI servisi şu an yanıt veremedi: #{error.message}", status: :bad_gateway, code: "ai_error")
      end

      def render_internal_error(error)
        raise error if Rails.env.test? && ENV["RAISE_IN_TESTS"]

        Rails.logger.error("[api] #{error.class}: #{error.message}\n#{error.backtrace&.first(8)&.join("\n")}")
        render_error("Beklenmeyen bir sunucu hatası oluştu", status: :internal_server_error, code: "internal_error")
      end

      def page_param
        [ params.fetch(:page, 1).to_i, 1 ].max
      end

      def paginate(scope)
        total = scope.count
        records = scope.offset((page_param - 1) * PER_PAGE).limit(PER_PAGE)
        [ records, { page: page_param, per_page: PER_PAGE, total: total, total_pages: (total.to_f / PER_PAGE).ceil } ]
      end

      def audit!(action, target = nil, metadata = {})
        AuditLog.record!(actor: current_user, action: action, target: target, metadata: metadata)
      end
    end
  end
end
