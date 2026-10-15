module Api
  module V1
    class IncidentTicketsController < BaseController
      before_action :set_incident

      def create
        ticket = Ticket.find(params.require(:ticket_id))
        IncidentOperations.new(@incident, actor: current_user).link_ticket!(ticket)
        render json: { incident: @incident.reload.detail_json }, status: :created
      end

      def destroy
        ticket = Ticket.find(params[:id])
        IncidentOperations.new(@incident, actor: current_user).unlink_ticket!(ticket)
        render json: { incident: @incident.reload.detail_json }
      end

      private

      def set_incident
        @incident = Incident.find(params[:incident_id])
        raise Authorization::Forbidden, "Kapanmış bir olayın ticket listesi değiştirilemez" if @incident.resolved? || @incident.dismissed?
      end
    end
  end
end
