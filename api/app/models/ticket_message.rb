class TicketMessage < ApplicationRecord
  belongs_to :ticket, touch: true
  belongs_to :user, optional: true

  enum :author_type, { agent: "agent", customer: "customer", system: "system" }, validate: true, prefix: :by
  # manual: typed by a person; ai_draft: an AI-prepared draft that a person reviewed and sent;
  # knowledge: inserted from a knowledge article; incident: bulk incident reply.
  ORIGINS = %w[manual ai_draft knowledge incident].freeze

  validates :body, presence: true, length: { maximum: 10_000 }
  validates :origin, inclusion: { in: ORIGINS }
  validate :customer_messages_are_public

  def author_name
    return user.name if user
    return ticket.customer.name if by_customer?

    "Sistem"
  end

  def as_api_json
    {
      id: id,
      body: body,
      internal: internal,
      author_type: author_type,
      author_name: author_name,
      origin: origin,
      created_at: created_at
    }
  end

  private

  def customer_messages_are_public
    errors.add(:internal, "müşteri mesajı iç not olamaz") if by_customer? && internal
  end
end
