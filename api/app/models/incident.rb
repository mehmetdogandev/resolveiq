class Incident < ApplicationRecord
  belongs_to :detected_by_run, class_name: "AgentRun", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true

  has_many :incident_tickets, dependent: :delete_all
  has_many :tickets, through: :incident_tickets
  has_many :agent_runs, as: :subject, dependent: :nullify

  enum :status, { proposed: "proposed", confirmed: "confirmed", resolved: "resolved", dismissed: "dismissed" }, validate: true
  enum :severity, { low: "low", medium: "medium", high: "high", critical: "critical" }, validate: true, prefix: :severity

  validates :title, presence: true, length: { maximum: 200 }
  validates :summary, presence: true
  validates :confidence, numericality: { in: 0..1 }, allow_nil: true

  scope :active, -> { where(status: %w[proposed confirmed]) }

  def code
    "INC-#{id.to_s.rjust(3, '0')}"
  end

  def affected_customers
    tickets.distinct.count(:customer_id)
  end

  def summary_json
    {
      id: id, code: code, title: title, summary: summary, status: status, severity: severity,
      confidence: confidence&.to_f, product: product, product_name: Catalog::PRODUCTS[product],
      ticket_count: incident_tickets.size, affected_customers: affected_customers,
      has_resolution_plan: resolution_plan.present?, resolution_applied_at: resolution_applied_at,
      created_at: created_at, confirmed_at: confirmed_at, resolved_at: resolved_at
    }
  end

  def detail_json
    summary_json.merge(
      suspected_root_cause: suspected_root_cause,
      uncertainty: uncertainty,
      symptoms: symptoms,
      evidence: evidence,
      suggested_actions: suggested_actions,
      recommended_next_action: recommended_next_action,
      resolution_plan: resolution_plan,
      resolution_note: resolution_note,
      confirmed_by: confirmed_by&.summary_json,
      detected_by_run: detected_by_run&.as_api_json,
      tickets: incident_tickets.includes(ticket: %i[customer assignee]).sort_by { |it| -(it.similarity || 0) }.map do |it|
        TicketPresenter.summary(it.ticket).merge(similarity: it.similarity&.to_f)
      end
    )
  end
end
