module Api
  module V1
    class TicketsController < BaseController
      before_action :set_ticket, only: %i[show update resolve reopen]

      SORTS = {
        "newest" => { created_at: :desc },
        "oldest" => { created_at: :asc },
        "updated" => { updated_at: :desc }
      }.freeze

      def index
        scope = Ticket.includes(:customer, :assignee).filtered(params)
        scope = params[:sort] == "priority" ? scope.order(Ticket::PRIORITY_ORDER, created_at: :desc) : scope.order(SORTS.fetch(params[:sort], SORTS["newest"]))
        records, meta = paginate(scope)
        counts = Ticket.filtered(params.except(:channel)).group(:channel).count
        render json: { tickets: records.map { |t| TicketPresenter.summary(t) }, meta: meta.merge(channel_counts: counts) }
      end

      def show
        render json: { ticket: TicketPresenter.detail(@ticket, viewer: current_user) }
      end

      def create
        attrs = params.require(:ticket).permit(:subject, :description, :customer_id, :channel, :priority, :category, :product, :assignee_id)
        attrs[:customer_id] = nil unless Customer.exists?(id: attrs[:customer_id])
        ticket = TicketOperations.create!(attrs.to_h.compact_blank, actor: current_user)
        render json: { ticket: TicketPresenter.summary(ticket.reload) }, status: :created
      end

      def update
        attrs = params.require(:ticket).permit(:subject, :status, :priority, :category, :product, :assignee_id)
        attrs[:assignee_id] = nil if attrs.key?(:assignee_id) && attrs[:assignee_id].blank?
        attrs[:category] = nil if attrs.key?(:category) && attrs[:category].blank?
        attrs[:product] = nil if attrs.key?(:product) && attrs[:product].blank?
        TicketOperations.new(@ticket, actor: current_user).update!(attrs.to_h)
        render json: { ticket: TicketPresenter.detail(@ticket.reload, viewer: current_user) }
      end

      def resolve
        TicketOperations.new(@ticket, actor: current_user).resolve!
        render json: { ticket: TicketPresenter.detail(@ticket.reload, viewer: current_user) }
      end

      def reopen
        TicketOperations.new(@ticket, actor: current_user).reopen!
        render json: { ticket: TicketPresenter.detail(@ticket.reload, viewer: current_user) }
      end

      private

      def set_ticket
        @ticket = Ticket.includes(:customer, :assignee).find(params[:id])
      end
    end
  end
end
