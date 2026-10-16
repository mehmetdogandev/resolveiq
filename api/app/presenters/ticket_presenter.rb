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
      tags: ticket.tags,
      customer: ticket.customer.summary_json,
      assignee: ticket.assignee&.summary_json,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at,
      resolved_at: ticket.resolved_at,
      first_response_at: ticket.first_response_at,
      sla: sla_json(ticket),
      merged_into_id: ticket.merged_into_id
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
      related_tickets: related_json(ticket),
      merged_tickets: ticket.merged_tickets.includes(:customer, :assignee).map { |t| summary(t) },
      incident_suggestions: incident_suggestions(ticket),
      activity: activity.map(&:as_api_json),
      csat: ticket.csat_rating&.as_api_json,
      customer_history: {
        total_tickets: ticket.customer.tickets.not_merged.count,
        open_tickets: ticket.customer.tickets.not_merged.unresolved.count
      },
      permissions: { can_manage: viewer&.manager? || false }
    )
  end

  def sla_json(ticket)
    return nil if ticket.sla_policy_id.blank? && ticket.sla_policy.blank?

    policy = ticket.sla_policy
    {
      policy_id: policy&.id,
      policy_name: policy&.name,
      first_response_due_at: ticket.first_response_due_at,
      resolution_due_at: ticket.resolution_due_at,
      breached_at: ticket.sla_breached_at,
      state: ticket.sla_state
    }
  end

  def related_json(ticket)
    ticket.ticket_links.includes(:related_ticket).filter_map do |link|
      next unless link.related_ticket

      summary(link.related_ticket).merge(link_kind: link.kind)
    end
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
