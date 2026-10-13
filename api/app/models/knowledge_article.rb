class KnowledgeArticle < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  has_many :ticket_articles, dependent: :delete_all
  has_many :tickets, through: :ticket_articles

  enum :status, { draft: "draft", published: "published" }, validate: true
  SOURCES = %w[manual ai_draft].freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :body, presence: true, length: { maximum: 20_000 }
  validates :slug, presence: true, uniqueness: true
  validates :source, inclusion: { in: SOURCES }
  validates :product, inclusion: { in: Catalog::PRODUCTS.keys }, allow_blank: true
  validates :category, inclusion: { in: Catalog::CATEGORIES.keys }, allow_blank: true

  before_validation :ensure_slug
  before_validation :normalize_tags
  before_save :stamp_published_at

  scope :search, ->(q) {
    term = "%#{sanitize_sql_like(q.to_s.strip)}%"
    where(
      "knowledge_articles.title ILIKE :t OR knowledge_articles.body ILIKE :t OR knowledge_articles.category ILIKE :t " \
      "OR knowledge_articles.product ILIKE :t OR array_to_string(knowledge_articles.tags, ' ') ILIKE :t",
      t: term
    )
  }

  def self.find_by_id_or_slug!(value)
    value.to_s.match?(/\A\d+\z/) ? find(value) : find_by!(slug: value)
  end

  def excerpt(length = 180)
    body.gsub(/[#*_>`-]/, " ").squish.truncate(length)
  end

  # Numbered/bulleted lines from the article body, used to build reply drafts.
  def steps
    body.lines.map(&:strip).select { |line| line.match?(/\A(\d+[.)]|[-*])\s+/) }.map { |line| line.sub(/\A(\d+[.)]|[-*])\s+/, "") }
  end

  def summary_json
    {
      id: id, title: title, slug: slug, product: product, product_name: Catalog::PRODUCTS[product],
      category: category, category_name: Catalog::CATEGORIES[category], tags: tags, status: status,
      source: source, excerpt: excerpt, updated_at: updated_at, published_at: published_at
    }
  end

  def detail_json
    summary_json.merge(body: body, steps: steps, author: author&.summary_json, linked_tickets_count: ticket_articles.size)
  end

  private

  def ensure_slug
    return if slug.present? || title.blank?

    base = title.to_s.downcase(:turkic).tr("çğıöşü", "cgiosu").parameterize.presence || "makale"
    candidate = base
    suffix = 2
    while KnowledgeArticle.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end

  def normalize_tags
    self.tags = Array(tags).flat_map { |t| t.to_s.split(",") }.map { |t| t.strip.downcase }.reject(&:blank?).uniq.first(12)
  end

  def stamp_published_at
    self.published_at = published? ? (published_at || Time.current) : nil
  end
end
