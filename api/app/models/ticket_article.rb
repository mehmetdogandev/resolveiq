class TicketArticle < ApplicationRecord
  belongs_to :ticket
  belongs_to :knowledge_article
  belongs_to :linked_by, class_name: "User", optional: true

  validates :knowledge_article_id, uniqueness: { scope: :ticket_id }
end
