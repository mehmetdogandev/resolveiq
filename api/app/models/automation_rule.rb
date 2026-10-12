class AutomationRule < ApplicationRecord
  EVENTS = %w[ticket_created ticket_updated].freeze

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { active.where(event: event).order(:position, :id) }

  validates :name, presence: true
  validates :event, inclusion: { in: EVENTS }

  def matches?(ticket)
    cond = (conditions || {}).stringify_keys
    text = "#{ticket.subject} #{ticket.description} #{Array(ticket.tags).join(' ')}".downcase(:turkic)

    keywords = Array(cond["keywords"]).map { |k| k.to_s.strip.downcase(:turkic) }.reject(&:blank?)
    return false if keywords.any? && keywords.none? { |word| text.include?(word) }
    return false if cond["channel"].present? && ticket.channel != cond["channel"]
    return false if cond["priority"].present? && ticket.priority != cond["priority"]
    return false if cond["category"].present? && ticket.category != cond["category"]
    return false if cond["product"].present? && ticket.product != cond["product"]
    true
  end

  def as_api_json
    { id: id, name: name, event: event, conditions: conditions, actions: actions, position: position }
  end
end
