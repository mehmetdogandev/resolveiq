module Api
  module V1
    class AiController < BaseController
      rate_limit to: 30, within: 1.minute, by: -> { current_user&.id || request.remote_ip },
                 with: -> { render_error("Çok fazla AI isteği. Biraz sonra tekrar deneyin.", status: :too_many_requests, code: "rate_limited") }

      def triage
        ticket = Ticket.find(params[:id])
        run = TriageAgent.call(ticket, user: current_user)
        audit!("ticket.triage_requested", ticket, agent_run_id: run.id, source: run.source)
        render json: { run: run.as_api_json }, status: :created
      end

      def apply_triage
        ticket = Ticket.find(params[:id])
        run = AgentRun.find(params.require(:run_id))
        TriageApplier.call(ticket: ticket, run: run, actor: current_user,
                           fields: params.fetch(:fields, TriageApplier::FIELDS),
                           link_articles: params.fetch(:link_articles, true) != false)
        render json: { ticket: TicketPresenter.detail(ticket.reload, viewer: current_user) }
      end

      def pattern_scan
        result = PatternDetector.call(user: current_user)
        render json: {
          groups_found: result[:groups_found],
          candidates_scanned: result[:candidates_scanned],
          proposals: result[:proposals].map { |p| { incident: p.incident.summary_json, run: p.run.as_api_json, created: p.created } }
        }
      end

      def prepare_incident_resolution
        incident = Incident.find(params[:id])
        raise ArgumentError, "Kapanmış bir olay için çözüm hazırlanamaz" if incident.resolved? || incident.dismissed?

        run = ResolutionAgent.for_incident(incident, user: current_user)
        render json: { run: run.as_api_json, incident: incident.reload.detail_json }, status: :created
      end

      def prepare_ticket_resolution
        ticket = Ticket.find(params[:id])
        run = ResolutionAgent.for_ticket(ticket, user: current_user)
        render json: { run: run.as_api_json }, status: :created
      end
    end
  end
end
