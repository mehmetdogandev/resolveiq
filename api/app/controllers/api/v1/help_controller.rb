module Api
  module V1
    class HelpController < BaseController
      allow_unauthenticated_access
      rate_limit to: 8, within: 1.minute, only: :create_request,
                 with: -> { render_error("Çok fazla talep. Bir dakika sonra tekrar deneyin.", status: :too_many_requests, code: "rate_limited") }

      def articles
        scope = KnowledgeArticle.published.order(published_at: :desc)
        scope = scope.search(params[:q]) if params[:q].present?
        scope = scope.where(category: params[:category]) if params[:category].present?
        scope = scope.where(product: params[:product]) if params[:product].present?
        render json: {
          articles: scope.limit(40).map(&:summary_json),
          categories: Catalog::CATEGORIES.map { |code, name| { code: code, name: name } },
          products: Catalog::PRODUCTS.map { |code, name| { code: code, name: name } }
        }
      end

      def article
        article = KnowledgeArticle.published.find_by_id_or_slug!(params[:id])
        render json: { article: article.detail_json.except(:author) }
      end

      def create_request
        payload = params.require(:request).permit(:name, :email, :subject, :description, :product)
        raise ArgumentError, "Ad, e-posta, konu ve açıklama zorunludur" if %i[name email subject description].any? { |k| payload[k].blank? }

        customer = Customer.find_or_initialize_by(email: payload[:email].to_s)
        customer.name = payload[:name] if customer.new_record? || customer.name.blank?
        customer.save!

        ticket = TicketOperations.create!(
          {
            subject: payload[:subject],
            description: payload[:description],
            customer_id: customer.id,
            channel: "web",
            product: payload[:product].presence
          }.compact,
          actor: nil
        )
        render json: { ticket: { number: ticket.number, id: ticket.id } }, status: :created
      end
    end
  end
end
