class Ticket < ApplicationRecord
  NUMBER_OFFSET = 1000

  belongs_to :customer
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :sla_policy, optional: true
  belongs_to :merged_into, class_name: "Ticket", optional: true

  has_many :messages, -> { order(:created_at, :id) }, class_name: "TicketMessage", dependent: :delete_all, inverse_of: :ticket
  has_many :ticket_articles, dependent: :delete_all
  has_many :articles, through: :ticket_articles, source: :knowledge_article
  has_many :incident_tickets, dependent: :delete_all
  has_many :incidents, through: :incident_tickets
  has_many :agent_runs, as: :subject, dependent: :nullify
  has_many :ticket_links, dependent: :delete_all
  has_many :related_tickets, through: :ticket_links, source: :related_ticket
  has_many :merged_tickets, class_name: "Ticket", foreign_key: :merged_into_id, inverse_of: :merged_into, dependent: :nullify
  has_one :csat_rating, dependent: :delete

  enum :channel, { email: "email", web: "web", chat: "chat" }, validate: true, prefix: :via
  enum :status, { open: "open", in_progress: "in_progress", pending: "pending", resolved: "resolved" }, validate: true
  enum :priority, { low: "low", normal: "normal", high: "high", urgent: "urgent" }, validate: true, prefix: :priority

  validates :subject, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 10_000 }
  validates :category, inclusion: { in: Catalog::CATEGORIES.keys }, allow_nil: true
  validates :product, inclusion: { in: Catalog::PRODUCTS.keys }, allow_nil: true

  before_validation :sync_resolved_at
  before_validation :normalize_tags
  after_create :assign_number

  scope :unresolved, -> { where.not(status: "resolved") }
  scope :not_merged, -> { where(merged_into_id: nil) }

  scope :search, ->(q) {
    term = "%#{sanitize_sql_like(q.to_s.strip)}%"
    left_joins(:customer).where(
      "tickets.number ILIKE :t OR tickets.subject ILIKE :t OR tickets.description ILIKE :t OR " \
      "customers.name ILIKE :t OR customers.company ILIKE :t OR tickets.product ILIKE :t OR " \
      "array_to_string(tickets.tags, ' ') ILIKE :t",
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
    scope = scope.not_merged unless params[:include_merged].to_s == "true"
    if params[:tag].present?
      tags = Array(params[:tag]).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
      scope = scope.where("tickets.tags && ARRAY[?]::varchar[]", tags) if tags.any?
    end
    scope = sla_breached_scope(scope) if params[:sla].to_s == "breached"
    scope
  end

  def self.sla_breached_scope(scope)
    now = Time.current
    scope.where.not(sla_policy_id: nil).where(
      "sla_breached_at IS NOT NULL OR " \
      "(first_response_at IS NULL AND first_response_due_at IS NOT NULL AND first_response_due_at < :now) OR " \
      "(status <> 'resolved' AND resolution_due_at IS NOT NULL AND resolution_due_at < :now) OR " \
      "(first_response_at IS NOT NULL AND first_response_due_at IS NOT NULL AND first_response_at > first_response_due_at) OR " \
      "(resolved_at IS NOT NULL AND resolution_due_at IS NOT NULL AND resolved_at > resolution_due_at)",
      now: now
    )
  end

  def merged?
    merged_into_id.present?
  end

  def sla_breached?
    return false if sla_policy_id.blank?
    return true if sla_breached_at.present?
    now = Time.current
    return true if first_response_at.nil? && first_response_due_at && now > first_response_due_at
    return true if !resolved? && resolution_due_at && now > resolution_due_at
    return true if first_response_at && first_response_due_at && first_response_at > first_response_due_at
    return true if resolved_at && resolution_due_at && resolved_at > resolution_due_at
    false
  end

  def sla_state
    return "none" if sla_policy_id.blank?
    return "breached" if sla_breached?
    return "met" if resolved?
    now = Time.current
    nearest = [ (first_response_due_at unless first_response_at), resolution_due_at ].compact.min
    return "ok" unless nearest && nearest > now

    remaining = nearest - now
    total = nearest - (created_at || now)
    return "warning" if total.positive? && remaining <= (total * 0.2)
    "ok"
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

  def normalize_tags
    self.tags = Array(tags).flat_map { |t| t.to_s.split(",") }.map { |t| t.strip.downcase }.reject(&:blank?).uniq.first(16)
  end
end
