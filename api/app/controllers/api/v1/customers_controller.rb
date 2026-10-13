module Api
  module V1
    class CustomersController < BaseController
      def index
        scope = Customer.order(:name)
        scope = scope.search(params[:q]) if params[:q].present?
        render json: { customers: scope.limit(50).map(&:summary_json) }
      end

      def show
        customer = Customer.find(params[:id])
        tickets = customer.tickets.includes(:assignee, :customer).order(created_at: :desc).limit(50)
        products = customer.tickets.where.not(product: nil).distinct.pluck(:product)
        render json: {
          customer: customer.summary_json.merge(
            since: customer.created_at,
            products: products.map { |code| { code: code, name: Catalog::PRODUCTS[code] } },
            stats: {
              total: customer.tickets.count,
              open: customer.tickets.unresolved.count,
              resolved: customer.tickets.resolved.count,
              by_channel: customer.tickets.group(:channel).count
            }
          ),
          tickets: tickets.map { |t| TicketPresenter.summary(t) }
        }
      end
    end
  end
end
