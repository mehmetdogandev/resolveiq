class SlaPolicy < ApplicationRecord
  has_many :tickets, dependent: :nullify

  scope :active, -> { where(active: true) }

  validates :name, presence: true, uniqueness: true
  validates :first_reply_minutes, :resolution_minutes, numericality: { greater_than: 0 }
  validates :priority, inclusion: { in: Ticket.priorities.keys }, allow_nil: true
  validates :channel, inclusion: { in: Ticket.channels.keys }, allow_nil: true

  def matches?(ticket)
    (priority.blank? || ticket.priority == priority) && (channel.blank? || ticket.channel == channel)
  end

  def self.for_ticket(ticket)
    active.order(:position, :id).find { |policy| policy.matches?(ticket) }
  end

  def as_api_json
    {
      id: id,
      name: name,
      first_reply_minutes: first_reply_minutes,
      resolution_minutes: resolution_minutes,
      priority: priority,
      channel: channel
    }
  end
end
