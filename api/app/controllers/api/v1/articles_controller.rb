module Api
  module V1
    class ArticlesController < BaseController
      before_action :set_article, only: %i[show update publish unpublish]

      def index
        scope = KnowledgeArticle.order(Arel.sql("knowledge_articles.status = 'published' DESC"), updated_at: :desc)
        scope = scope.search(params[:q]) if params[:q].present?
        scope = scope.where(product: params[:product]) if params[:product].present?
        scope = scope.where(category: params[:category]) if params[:category].present?
        scope = scope.where(status: params[:status]) if KnowledgeArticle.statuses.key?(params[:status].to_s)
        render json: { articles: scope.limit(60).map(&:summary_json), counts: KnowledgeArticle.group(:status).count }
      end

      def show
        render json: { article: @article.detail_json }
      end

      # Anyone can create a draft (including AI-proposed drafts); only managers publish.
      def create
        attrs = article_params
        article = KnowledgeArticle.new(attrs.merge(author: current_user, status: "draft"))
        article.source = "ai_draft" if params.dig(:article, :source) == "ai_draft"
        article.save!
        audit!("article.created", article, source: article.source, agent_run_id: params.dig(:article, :agent_run_id))
        render json: { article: article.detail_json }, status: :created
      end

      def update
        require_manager! if @article.published?
        @article.update!(article_params)
        audit!("article.updated", @article)
        render json: { article: @article.detail_json }
      end

      def publish
        require_manager!
        @article.update!(status: "published")
        audit!("article.published", @article)
        render json: { article: @article.detail_json }
      end

      def unpublish
        require_manager!
        @article.update!(status: "draft")
        audit!("article.unpublished", @article)
        render json: { article: @article.detail_json }
      end

      private

      def set_article
        @article = KnowledgeArticle.find_by_id_or_slug!(params[:id])
      end

      def article_params
        attrs = params.require(:article).permit(:title, :body, :product, :category, tags: [])
        attrs[:tags] = params.dig(:article, :tags).to_s.split(",") if params.dig(:article, :tags).is_a?(String)
        attrs
      end
    end
  end
end
