module Api
  module V1
    class IncidentsController < BaseController
      before_action :set_incident, except: :index
      before_action :require_manager!, only: %i[confirm dismiss resolve apply_resolution]

      def index
        scope = Incident.includes(:incident_tickets).order(Arel.sql("CASE incidents.status WHEN 'proposed' THEN 0 WHEN 'confirmed' THEN 1 WHEN 'resolved' THEN 2 ELSE 3 END"), created_at: :desc)
        scope = scope.where(status: params[:status]) if Incident.statuses.key?(params[:status].to_s)
        render json: { incidents: scope.limit(50).map(&:summary_json) }
      end

      def show
        render json: { incident: @incident.detail_json }
      end

      def confirm
        ops.confirm!
        render json: { incident: @incident.reload.detail_json }
      end

      def dismiss
        ops.dismiss!
        render json: { incident: @incident.reload.detail_json }
      end

      def resolve
        ops.resolve!(note: params[:note])
        render json: { incident: @incident.reload.detail_json }
      end

      def apply_resolution
        tickets = ops.apply_resolution!(
          reply_body: params.require(:reply_body).to_s,
          ticket_ids: Array(params.require(:ticket_ids)).map(&:to_i),
          status: params.fetch(:status, "pending").to_s,
          internal_note: params[:internal_note].presence
        )
        render json: { incident: @incident.reload.detail_json, updated_tickets: tickets.map(&:number) }
      end

      private

      def set_incident
        @incident = Incident.find(params[:id])
      end

      def ops
        IncidentOperations.new(@incident, actor: current_user)
      end
    end
  end
end
