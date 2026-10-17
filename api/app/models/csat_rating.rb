class CsatRating < ApplicationRecord
  belongs_to :ticket
  belongs_to :customer

  validates :score, inclusion: { in: 1..5 }
  validates :ticket_id, uniqueness: true
  validates :comment, length: { maximum: 2_000 }, allow_blank: true

  def as_api_json
    { id: id, score: score, comment: comment, created_at: created_at }
  end
end
