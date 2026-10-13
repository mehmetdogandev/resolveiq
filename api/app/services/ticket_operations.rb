# All ticket mutations go through here so audit logging, timestamps and
# authorization rules stay consistent between the UI actions and AI "apply" actions.
class TicketOperations
  UPDATABLE = %i[subject status priority category product assignee_id].freeze

  def initialize(ticket, actor:)
    @ticket = ticket
    @actor = actor
  end

  def self.create!(attrs, actor:)
    ticket = Ticket.new(attrs.merge(created_by: actor))
    ticket.status ||= "open"
    Ticket.transaction do
      ticket.save!
      ticket.messages.create!(author_type: "customer", body: ticket.description, internal: false, created_at: ticket.created_at)
      AuditLog.record!(actor: actor, action: "ticket.created", target: ticket,
                       metadata: { channel: ticket.channel, priority: ticket.priority, number: ticket.number })
    end
    ticket
  end

  def update!(attrs, action: "ticket.updated", extra: {})
    attrs = attrs.to_h.symbolize_keys.slice(*UPDATABLE)
    validate_assignee!(attrs[:assignee_id]) if attrs.key?(:assignee_id)

    @ticket.assign_attributes(attrs)
    changes = @ticket.changes_to_save.except("updated_at", "resolved_at")
    return @ticket if changes.empty?

    Ticket.transaction do
      @ticket.save!
      AuditLog.record!(actor: @actor, action: action, target: @ticket,
                       metadata: extra.merge(changes: changes.transform_values { |(from, to)| { from: from, to: to } }))
    end
    @ticket
  end

  def reply!(body:, internal: false, origin: "manual", status: nil)
    raise ArgumentError, "Geçersiz durum" if status.present? && !Ticket.statuses.key?(status.to_s)

    message = nil
    Ticket.transaction do
      message = @ticket.messages.create!(user: @actor, author_type: "agent", body: body, internal: internal, origin: origin)
      @ticket.first_response_at ||= message.created_at unless internal
      @ticket.status = "in_progress" if !internal && @ticket.open? && status.blank?
      @ticket.status = status if status.present?
      @ticket.save!
      AuditLog.record!(actor: @actor, action: internal ? "ticket.internal_note_added" : "ticket.reply_sent", target: @ticket,
                       metadata: { message_id: message.id, origin: origin, status: @ticket.status })
    end
    message
  end

  def resolve!
    update!({ status: "resolved" }, action: "ticket.resolved")
  end

  def reopen!
    update!({ status: "open" }, action: "ticket.reopened")
  end

  def link_article!(article)
    raise Authorization::Forbidden, "Taslak makaleler ticket'a bağlanamaz" unless article.published?

    link = @ticket.ticket_articles.find_or_create_by!(knowledge_article: article) { |ta| ta.linked_by = @actor }
    AuditLog.record!(actor: @actor, action: "ticket.article_linked", target: @ticket, metadata: { article_id: article.id, title: article.title })
    link
  end

  def unlink_article!(article)
    deleted = @ticket.ticket_articles.where(knowledge_article: article).delete_all
    AuditLog.record!(actor: @actor, action: "ticket.article_unlinked", target: @ticket, metadata: { article_id: article.id }) if deleted.positive?
  end

  private

  def validate_assignee!(assignee_id)
    return if assignee_id.blank?

    raise ArgumentError, "Atanan kullanıcı bulunamadı" unless User.exists?(id: assignee_id)
  end
end
