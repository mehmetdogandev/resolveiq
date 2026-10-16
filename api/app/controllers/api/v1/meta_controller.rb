module Api
  module V1
    class MetaController < BaseController
      def show
        open_counts = Ticket.unresolved.group(:assignee_id).count
        render json: Catalog.as_json.merge(
          users: User.order(:role, :name).map { |u| u.summary_json.merge(open_tickets: open_counts[u.id].to_i) },
          customers: Customer.order(:name).limit(200).map(&:summary_json),
          macros: Macro.active.map(&:as_api_json),
          ai: { configured: Llm.configured?, mode: Llm.mode, model: Llm.mode == "openai" ? Llm.model : nil }
        )
      end
    end
  end
end
