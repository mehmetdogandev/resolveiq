# Applies the safe, field-level parts of a triage run in one explicit action.
# The reply draft is never sent automatically.
class TriageApplier
  FIELDS = %w[category priority assignee].freeze

  def self.call(ticket:, run:, actor:, fields: FIELDS, link_articles: true)
    raise ArgumentError, "Bu öneri bu ticket'a ait değil" unless run.subject == ticket && run.agent_type == "triage"
    raise ArgumentError, "Başarısız bir AI çalıştırması uygulanamaz" unless run.succeeded?

    out = run.output
    fields = Array(fields).map(&:to_s) & FIELDS
    attrs = {}
    attrs[:category] = out["category"] if fields.include?("category") && out["category"]
    attrs[:priority] = out["priority"] if fields.include?("priority") && out["priority"]
    attrs[:assignee_id] = out["assignee_id"] if fields.include?("assignee") && out["assignee_id"]

    ops = TicketOperations.new(ticket, actor: actor)
    Ticket.transaction do
      ops.update!(attrs, action: "ticket.triage_applied", extra: { agent_run_id: run.id, source: run.source }) if attrs.any?
      if link_articles
        KnowledgeArticle.published.where(id: Array(out["articles"]).map { |a| a["id"] }).find_each { |a| ops.link_article!(a) }
      end
      run.update!(applied_at: Time.current, applied_by: actor)
    end
    ticket.reload
  end
end
