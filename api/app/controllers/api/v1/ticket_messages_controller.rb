module Api
  module V1
    class TicketMessagesController < BaseController
      def create
        ticket = Ticket.find(params[:ticket_id])
        attrs = params.require(:message).permit(:body, :internal, :origin, :status)
        origin = TicketMessage::ORIGINS.include?(attrs[:origin]) ? attrs[:origin] : "manual"
        message = TicketOperations.new(ticket, actor: current_user)
                                  .reply!(body: attrs[:body].to_s, internal: ActiveModel::Type::Boolean.new.cast(attrs[:internal]) || false,
                                          origin: origin, status: attrs[:status].presence)
        render json: { message: message.as_api_json, ticket: TicketPresenter.detail(ticket.reload, viewer: current_user) }, status: :created
      end
    end
  end
end
