# Lifecycle of an incident hypothesis. Confirmation, dismissal, bulk replies and
# resolution are manager-only (enforced by the controller).
class IncidentOperations
  def initialize(incident, actor:)
    @incident = incident
    @actor = actor
  end

  def confirm!
    raise ArgumentError, "Yalnızca önerilen (proposed) bir olay onaylanabilir" unless @incident.proposed?

    @incident.update!(status: "confirmed", confirmed_by: @actor, confirmed_at: Time.current)
    audit("incident.confirmed")
  end

  def dismiss!
    raise ArgumentError, "Çözülmüş bir olay reddedilemez" if @incident.resolved?

    @incident.update!(status: "dismissed")
    audit("incident.dismissed")
  end

  def resolve!(note:)
    raise ArgumentError, "Önce olayı onaylayın" unless @incident.confirmed?

    @incident.update!(status: "resolved", resolved_at: Time.current, resolution_note: note.to_s.truncate(2000))
    audit("incident.resolved")
  end

  def link_ticket!(ticket)
    @incident.incident_tickets.find_or_create_by!(ticket: ticket) do |link|
      link.similarity = SimilarityIndex.max_similarity(ticket, @incident.tickets.to_a).round(3)
    end
    audit("incident.ticket_linked", ticket_number: ticket.number)
  end

  def unlink_ticket!(ticket)
    @incident.incident_tickets.where(ticket: ticket).delete_all
    audit("incident.ticket_unlinked", ticket_number: ticket.number)
  end

  # Sends the reviewed (possibly edited) shared reply to the selected linked tickets.
  def apply_resolution!(reply_body:, ticket_ids:, status:, internal_note: nil)
    raise ArgumentError, "Toplu aksiyon için olay önce onaylanmalı" unless @incident.confirmed?
    raise ArgumentError, "Yanıt metni boş olamaz" if reply_body.blank?
    raise ArgumentError, "Geçersiz durum" unless %w[pending resolved in_progress].include?(status)

    tickets = @incident.tickets.includes(:customer).where(id: ticket_ids).to_a
    raise ArgumentError, "Seçili ticket bulunamadı" if tickets.empty?

    Incident.transaction do
      tickets.each do |ticket|
        ops = TicketOperations.new(ticket, actor: @actor)
        body = reply_body.gsub("{{musteri_adi}}", ticket.customer.first_name)
        ops.reply!(body: body, internal: false, origin: "incident", status: status)
        ops.reply!(body: "#{@incident.code}: #{internal_note}", internal: true, origin: "incident") if internal_note.present?
      end
      @incident.update!(resolution_applied_at: Time.current)
      audit("incident.resolution_applied", ticket_numbers: tickets.map(&:number), status: status)
    end
    tickets
  end

  private

  def audit(action, metadata = {})
    AuditLog.record!(actor: @actor, action: action, target: @incident, metadata: metadata)
    @incident
  end
end
