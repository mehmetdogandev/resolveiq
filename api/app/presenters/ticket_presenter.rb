module TicketPresenter
  module_function

  def summary(ticket)
    {
      id: ticket.id,
      number: ticket.number,
      subject: ticket.subject,
      channel: ticket.channel,
      status: ticket.status,
      priority: ticket.priority,
      category: ticket.category,
      category_name: ticket.category_name,
      product: ticket.product,
      product_name: ticket.product_name,
      customer: ticket.customer.summary_json,
      assignee: ticket.assignee&.summary_json,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at,
      resolved_at: ticket.resolved_at,
      first_response_at: ticket.first_response_at
    }
  end

  def detail(ticket, viewer:)
    latest_triage = ticket.agent_runs.where(agent_type: "triage").recent.first
    latest_resolution = ticket.agent_runs.where(agent_type: "resolution").recent.first
    activity = AuditLog.for_target(ticket).includes(:actor).recent.limit(30)

    summary(ticket).merge(
      description: ticket.description,
      messages: ticket.messages.includes(:user).map(&:as_api_json),
      articles: ticket.ticket_articles.includes(:knowledge_article).order(:created_at).map { |ta| ta.knowledge_article.summary_json },
      incidents: ticket.incidents.order(created_at: :desc).map(&:summary_json),
      latest_triage: latest_triage&.as_api_json,
      latest_resolution: latest_resolution&.as_api_json,
      similar_tickets: SimilarityIndex.similar_to(ticket, limit: 5).map { |t, score| summary(t).merge(similarity: score.round(3)) },
      incident_suggestions: incident_suggestions(ticket),
      activity: activity.map(&:as_api_json),
      customer_history: {
        total_tickets: ticket.customer.tickets.count,
        open_tickets: ticket.customer.tickets.unresolved.count
      },
      permissions: { can_manage: viewer.manager? }
    )
  end

  # Active incidents this ticket looks like but is not linked to yet.
  def incident_suggestions(ticket)
    linked_ids = ticket.incident_ids
    Incident.active.where.not(id: linked_ids).includes(:tickets).filter_map do |incident|
      next if incident.product.present? && incident.product != ticket.product

      score = SimilarityIndex.max_similarity(ticket, incident.tickets)
      next if score < SimilarityIndex::LINK_THRESHOLD

      incident.summary_json.merge(similarity: score.round(3))
    end
  end
end
