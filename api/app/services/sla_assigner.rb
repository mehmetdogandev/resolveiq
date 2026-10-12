# Picks the first matching SLA policy and stamps due timestamps from created_at.
class SlaAssigner
  def self.assign!(ticket)
    policy = SlaPolicy.for_ticket(ticket)
    attrs = { sla_policy_id: policy&.id }
    if policy
      origin = ticket.created_at || Time.current
      attrs[:first_response_due_at] = origin + policy.first_reply_minutes.minutes
      attrs[:resolution_due_at] = origin + policy.resolution_minutes.minutes
    else
      attrs[:first_response_due_at] = nil
      attrs[:resolution_due_at] = nil
    end
    ticket.update_columns(attrs)
    ticket.reload
    refresh_breach!(ticket)
    ticket
  end

  def self.refresh_breach!(ticket)
    breached_at = ticket.sla_breached? ? (ticket.sla_breached_at || Time.current) : nil
    ticket.update_columns(sla_breached_at: breached_at) if ticket.sla_breached_at != breached_at
    ticket
  end
end
