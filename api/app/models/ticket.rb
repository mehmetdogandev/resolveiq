class Ticket < ApplicationRecord
  NUMBER_OFFSET = 1000

  belongs_to :customer
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :messages, -> { order(:created_at, :id) }, class_name: "TicketMessage", dependent: :delete_all, inverse_of: :ticket
  has_many :ticket_articles, dependent: :delete_all
  has_many :articles, through: :ticket_articles, source: :knowledge_article
  has_many :incident_tickets, dependent: :delete_all
  has_many :incidents, through: :incident_tickets
  has_many :agent_runs, as: :subject, dependent: :nullify

  enum :channel, { email: "email", web: "web", chat: "chat" }, validate: true, prefix: :via
  enum :status, { open: "open", in_progress: "in_progress", pending: "pending", resolved: "resolved" }, validate: true
  enum :priority, { low: "low", normal: "normal", high: "high", urgent: "urgent" }, validate: true, prefix: :priority

  validates :subject, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 10_000 }
  validates :category, inclusion: { in: Catalog::CATEGORIES.keys }, allow_nil: true
  validates :product, inclusion: { in: Catalog::PRODUCTS.keys }, allow_nil: true

  before_validation :sync_resolved_at
  after_create :assign_number

  scope :unresolved, -> { where.not(status: "resolved") }

  scope :search, ->(q) {
    term = "%#{sanitize_sql_like(q.to_s.strip)}%"
    left_joins(:customer).where(
      "tickets.number ILIKE :t OR tickets.subject ILIKE :t OR tickets.description ILIKE :t OR " \
      "customers.name ILIKE :t OR customers.company ILIKE :t OR tickets.product ILIKE :t",
      t: term
    )
  }

  PRIORITY_ORDER = Arel.sql("CASE tickets.priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END")

  def self.filtered(params)
    scope = all
    scope = scope.search(params[:q]) if params[:q].present?
    %i[channel status priority category product].each do |key|
      values = Array(params[key]).flat_map { |v| v.to_s.split(",") }.reject(&:blank?)
      scope = scope.where(key => values) if values.any?
    end
    scope = scope.where(status: %w[open in_progress pending]) if params[:open_only].to_s == "true"
    if params[:assignee_id].present?
      scope = params[:assignee_id] == "none" ? scope.where(assignee_id: nil) : scope.where(assignee_id: params[:assignee_id])
    end
    scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
    scope
  end

  def product_name
    Catalog::PRODUCTS[product]
  end

  def category_name
    Catalog::CATEGORIES[category]
  end

  def symptom_text
    "#{subject}. #{description}"
  end

  private

  def sync_resolved_at
    if resolved?
      self.resolved_at ||= Time.current
    else
      self.resolved_at = nil
    end
  end

  def assign_number
    update_column(:number, "RIQ-#{NUMBER_OFFSET + id}") if number.blank?
  end
end
