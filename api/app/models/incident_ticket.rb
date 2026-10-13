class IncidentTicket < ApplicationRecord
  belongs_to :incident
  belongs_to :ticket

  validates :ticket_id, uniqueness: { scope: :incident_id }
end
