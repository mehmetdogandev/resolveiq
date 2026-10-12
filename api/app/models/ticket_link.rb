class TicketLink < ApplicationRecord
  belongs_to :ticket
  belongs_to :related_ticket, class_name: "Ticket"

  enum :kind, { related: "related", merged: "merged" }, validate: true

  validates :related_ticket_id, uniqueness: { scope: :ticket_id }
  validate :not_self

  private

  def not_self
    errors.add(:related_ticket_id, "kendisine bağlanamaz") if ticket_id == related_ticket_id
  end
end
