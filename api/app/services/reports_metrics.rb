class ReportsMetrics
  def as_json(*)
    tickets = Ticket.not_merged
    with_policy = tickets.where.not(sla_policy_id: nil)
    breached = Ticket.sla_breached_scope(with_policy)
    met = with_policy.where.not(id: breached.select(:id))
    responded = tickets.where.not(first_response_at: nil)
    resolved = tickets.resolved

    {
      generated_at: Time.current,
      totals: {
        tickets: tickets.count,
        open: tickets.unresolved.count,
        resolved: resolved.count,
        breached_open: Ticket.sla_breached_scope(tickets.unresolved).count
      },
      first_reply: {
        average_minutes: average_minutes(responded, "first_response_at - tickets.created_at"),
        count: responded.count
      },
      resolution: {
        average_minutes: average_minutes(resolved, "resolved_at - tickets.created_at"),
        count: resolved.count
      },
      sla: {
        evaluated: with_policy.count,
        met: met.count,
        breached: breached.count,
        met_rate: rate(met.count, with_policy.count)
      },
      csat: csat_block,
      by_channel: channel_block(tickets),
      by_agent: agent_block(tickets),
      by_priority: Ticket.priorities.keys.index_with { |p| 0 }.merge(tickets.unresolved.group(:priority).count)
    }
  end

  private

  def average_minutes(scope, expression)
    value = scope.pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (#{expression})) / 60.0)"))
    value&.to_f&.round(1)
  end

  def rate(num, den)
    return nil if den.to_i.zero?

    (num.to_f / den).round(3)
  end

  def csat_block
    {
      average: CsatRating.average(:score)&.to_f&.round(2),
      count: CsatRating.count,
      distribution: (1..5).index_with { |s| 0 }.merge(CsatRating.group(:score).count.transform_keys(&:to_i))
    }
  end

  def channel_block(tickets)
    Ticket.channels.keys.index_with do |channel|
      subset = tickets.where(channel: channel)
      resolved = subset.resolved
      {
        tickets: subset.count,
        open: subset.unresolved.count,
        avg_first_reply_minutes: average_minutes(subset.where.not(first_response_at: nil), "first_response_at - tickets.created_at"),
        avg_resolution_minutes: average_minutes(resolved, "resolved_at - tickets.created_at")
      }
    end
  end

  def agent_block(tickets)
    User.order(:name).map do |user|
      assigned = tickets.where(assignee_id: user.id)
      resolved = assigned.resolved
      {
        user: user.summary_json,
        open: assigned.unresolved.count,
        resolved: resolved.count,
        avg_first_reply_minutes: average_minutes(assigned.where.not(first_response_at: nil), "first_response_at - tickets.created_at"),
        avg_resolution_minutes: average_minutes(resolved, "resolved_at - tickets.created_at"),
        csat_average: CsatRating.joins(:ticket).where(tickets: { assignee_id: user.id }).average(:score)&.to_f&.round(2)
      }
    end
  end
end
