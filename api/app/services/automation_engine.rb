# Runs seeded trigger rules after ticket create/update. Does not send email;
# it only mutates assignment, priority, category and tags.
class AutomationEngine
  def self.apply!(ticket, event:)
    AutomationRule.for_event(event).each do |rule|
      next unless rule.matches?(ticket)

      apply_actions!(ticket, rule.actions)
    end
    ticket
  end

  def self.apply_actions!(ticket, actions)
    actions = (actions || {}).stringify_keys
    changed = false

    if actions["priority"].present? && Ticket.priorities.key?(actions["priority"])
      ticket.priority = actions["priority"]
      changed = true
    end
    if actions["status"].present? && Ticket.statuses.key?(actions["status"])
      ticket.status = actions["status"]
      changed = true
    end
    if actions["category"].present? && Catalog::CATEGORIES.key?(actions["category"])
      ticket.category = actions["category"]
      changed = true
    end
    if actions["team"].present? && Catalog::TEAMS.key?(actions["team"]) && ticket.assignee_id.blank?
      ticket.assignee = least_busy_agent(actions["team"])
      changed = true
    end
    add_tags = Array(actions["add_tags"]).map { |t| t.to_s.strip.downcase }.reject(&:blank?)
    if add_tags.any?
      ticket.tags = (Array(ticket.tags) + add_tags).uniq
      changed = true
    end

    ticket.save! if changed
    ticket
  end

  def self.least_busy_agent(team)
    User.where(team: team).min_by { |user| user.assigned_tickets.unresolved.count }
  end
end
