module Api
  module V1
    class TicketArticlesController < BaseController
      before_action :set_ticket

      def create
        article = KnowledgeArticle.find(params.require(:article_id))
        TicketOperations.new(@ticket, actor: current_user).link_article!(article)
        render json: { ticket: TicketPresenter.detail(@ticket.reload, viewer: current_user) }, status: :created
      end

      def destroy
        article = KnowledgeArticle.find(params[:id])
        TicketOperations.new(@ticket, actor: current_user).unlink_article!(article)
        render json: { ticket: TicketPresenter.detail(@ticket.reload, viewer: current_user) }
      end

      private

      def set_ticket
        @ticket = Ticket.find(params[:ticket_id])
      end
    end
  end
end
