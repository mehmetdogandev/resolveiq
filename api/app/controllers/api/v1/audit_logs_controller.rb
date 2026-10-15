module Api
  module V1
    class AuditLogsController < BaseController
      before_action :require_manager!

      def index
        scope = AuditLog.includes(:actor).recent
        scope = scope.where(target_type: params[:target_type], target_id: params[:target_id]) if params[:target_type].present?
        scope = scope.where("action LIKE ?", "#{AuditLog.sanitize_sql_like(params[:action_prefix])}%") if params[:action_prefix].present?
        render json: { audit_logs: scope.limit(100).map(&:as_api_json) }
      end
    end
  end
end
