# All ticket mutations go through here so audit logging, timestamps and
# authorization rules stay consistent between the UI actions and AI "apply" actions.
class TicketOperations
  UPDATABLE = %i[subject status priority category product assignee_id tags].freeze

  def initialize(ticket, actor:)
    @ticket = ticket
    @actor = actor
  end

  def self.create!(attrs, actor:)
    attrs = attrs.to_h.symbolize_keys
    ticket = Ticket.new(attrs.merge(created_by: actor))
    ticket.status ||= "open"
    Ticket.transaction do
      ticket.save!
      ticket.messages.create!(author_type: "customer", body: ticket.description, internal: false, created_at: ticket.created_at)
      AutomationEngine.apply!(ticket, event: "ticket_created")
      SlaAssigner.assign!(ticket)
      AuditLog.record!(actor: actor, action: "ticket.created", target: ticket,
                       metadata: { channel: ticket.channel, priority: ticket.priority, number: ticket.number, tags: ticket.tags })
    end
    ticket.reload
  end

  def update!(attrs, action: "ticket.updated", extra: {})
    attrs = attrs.to_h.symbolize_keys.slice(*UPDATABLE)
    validate_assignee!(attrs[:assignee_id]) if attrs.key?(:assignee_id)

    @ticket.assign_attributes(attrs)
    changes = @ticket.changes_to_save.except("updated_at", "resolved_at")
    return @ticket if changes.empty?

    Ticket.transaction do
      @ticket.save!
      AutomationEngine.apply!(@ticket, event: "ticket_updated")
      SlaAssigner.assign!(@ticket)
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
      SlaAssigner.refresh_breach!(@ticket)
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

  def apply_macro!(macro)
    raise ArgumentError, "Makro aktif değil" unless macro.active?

    actions = (macro.actions || {}).stringify_keys
    Ticket.transaction do
      attrs = {}
      attrs[:status] = actions["status"] if actions["status"].present?
      attrs[:priority] = actions["priority"] if actions["priority"].present?
      attrs[:assignee_id] = actions["assignee_id"] if actions.key?("assignee_id")
      attrs[:tags] = (Array(@ticket.tags) + Array(actions["add_tags"])).uniq if actions["add_tags"].present?
      update!(attrs, action: "ticket.macro_applied", extra: { macro_id: macro.id, macro_name: macro.name }) if attrs.any?
      if actions["reply"].present?
        reply!(body: actions["reply"], internal: actions["reply_internal"] == true, origin: "manual", status: actions["reply_status"])
      end
    end
    @ticket.reload
  end

  def bulk_update!(attrs)
    update!(attrs, action: "ticket.bulk_updated")
  end

  def merge!(source_ids)
    ids = Array(source_ids).map(&:to_i).uniq - [ @ticket.id ]
    raise ArgumentError, "Birleştirilecek ticket seçilmedi" if ids.empty?
    raise ArgumentError, "Birleştirilmiş ticket'a kaynak eklenemez" if @ticket.merged?

    sources = Ticket.not_merged.where(id: ids)
    raise ArgumentError, "Kaynak ticket bulunamadı" if sources.size != ids.size

    Ticket.transaction do
      sources.find_each do |source|
        source.messages.update_all(ticket_id: @ticket.id)
        source.ticket_articles.find_each do |link|
          @ticket.ticket_articles.find_or_create_by!(knowledge_article_id: link.knowledge_article_id) { |ta| ta.linked_by_id = link.linked_by_id }
        end
        source.update!(merged_into: @ticket, status: "resolved")
        TicketLink.find_or_create_by!(ticket: @ticket, related_ticket: source) { |l| l.kind = "merged" }
        AuditLog.record!(actor: @actor, action: "ticket.merged", target: @ticket,
                         metadata: { source_id: source.id, source_number: source.number })
        AuditLog.record!(actor: @actor, action: "ticket.merged_into", target: source,
                         metadata: { target_id: @ticket.id, target_number: @ticket.number })
      end
    end
    @ticket.reload
  end

  def link_related!(other)
    raise ArgumentError, "Ticket kendisine bağlanamaz" if other.id == @ticket.id
    raise ArgumentError, "Birleştirilmiş ticket bağlanamaz" if other.merged? || @ticket.merged?

    Ticket.transaction do
      TicketLink.find_or_create_by!(ticket: @ticket, related_ticket: other) { |l| l.kind = "related" }
      TicketLink.find_or_create_by!(ticket: other, related_ticket: @ticket) { |l| l.kind = "related" }
      AuditLog.record!(actor: @actor, action: "ticket.related_linked", target: @ticket,
                       metadata: { related_id: other.id, related_number: other.number })
    end
    @ticket
  end

  def record_csat!(score:, comment: nil)
    raise ArgumentError, "CSAT yalnızca çözülmüş ticket'lara yazılır" unless @ticket.resolved?
    raise ArgumentError, "Bu ticket için CSAT zaten kaydedildi" if @ticket.csat_rating.present?

    rating = nil
    Ticket.transaction do
      rating = @ticket.create_csat_rating!(customer: @ticket.customer, score: score, comment: comment)
      AuditLog.record!(actor: @actor, action: "ticket.csat_recorded", target: @ticket, metadata: { score: score })
    end
    rating
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
