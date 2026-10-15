# Agent C: prepares a resolution package for an incident (shared customer reply,
# troubleshooting steps, escalation, KB gap proposal, per-ticket actions) or for
# a single ticket. It only drafts; people review, edit and apply.
class ResolutionAgent
  SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: %w[troubleshooting_steps customer_reply internal_escalation kb_gap kb_article ticket_actions article_ids],
    properties: {
      troubleshooting_steps: { type: "array", items: { type: "string" } },
      customer_reply: { type: "string" },
      internal_escalation: {
        type: "object", additionalProperties: false, required: %w[needed team summary],
        properties: { needed: { type: "boolean" }, team: { type: "string" }, summary: { type: "string" } }
      },
      kb_gap: { type: "boolean" },
      kb_article: {
        type: "object", additionalProperties: false, required: %w[title body tags],
        properties: { title: { type: "string" }, body: { type: "string" }, tags: { type: "array", items: { type: "string" } } }
      },
      ticket_actions: {
        type: "array",
        items: {
          type: "object", additionalProperties: false, required: %w[ticket_number action reason],
          properties: {
            ticket_number: { type: "string" },
            action: { type: "string", enum: %w[reply_and_pending reply_and_resolve link_only] },
            reason: { type: "string" }
          }
        }
      },
      article_ids: { type: "array", items: { type: "integer" } }
    }
  }.freeze

  SYSTEM = <<~PROMPT.freeze
    Sen ResolveIQ'nun çözüm ve önleme ajanısın (hayali marka: Northforge Tools). Sana bir olay (incident)
    hipotezi veya tek bir ticket, ilgili ticket kanıtları, bilgi bankası makaleleri ve önceki çözüm yanıtları verilecek.
    Üret:
    - troubleshooting_steps: müşterinin güvenle uygulayabileceği 3-6 adım. Cihazı açmayı/sökmeyi önerme.
    - customer_reply: tüm etkilenen müşterilere gidebilecek nazik Türkçe yanıt. Müşteri adı yerine {{musteri_adi}} yer tutucusunu kullan.
      Kesinleşmemiş nedeni kesin gibi yazma; garanti/iade sözü verme, "inceleme sürüyor" de.
    - internal_escalation: gerekiyorsa hangi ekibe ve ne özetle eskale edileceği.
    - kb_gap: mevcut makaleler bu durumu karşılamıyorsa true; kb_article ile yayınlanabilir bir taslak öner (markdown, numaralı adımlar).
    - ticket_actions: incident için her ilgili ticket'a bir aksiyon (tek ticket isteğinde boş dizi).
    - article_ids: yalnızca verilen makale ID'lerinden ilgili olanlar.
  PROMPT

  def self.for_incident(incident, user:)
    new(user).run_for(incident)
  end

  def self.for_ticket(ticket, user:)
    new(user).run_for(ticket)
  end

  def initialize(user)
    @user = user
  end

  def run_for(subject)
    @subject = subject
    @tickets = subject.is_a?(Incident) ? subject.tickets.includes(:customer).to_a : [ subject ]
    run = AgentRunner.call(agent_type: "resolution", subject: subject, user: @user,
                           task: "resolution_plan", system: SYSTEM, prompt: prompt, schema: SCHEMA,
                           fallback: -> { fallback_output }) do |data|
      sanitize(data)
    end
    subject.update!(resolution_plan: run.output.merge("agent_run_id" => run.id)) if subject.is_a?(Incident)
    AuditLog.record!(actor: @user, action: "#{subject.class.name.underscore}.resolution_prepared", target: subject,
                     metadata: { agent_run_id: run.id, source: run.source })
    run
  end

  private

  def product
    @subject.product
  end

  def articles
    @articles ||= begin
      scope = KnowledgeArticle.published
      scoped = product.present? ? scope.where(product: [ product, nil, "" ]) : scope
      tokens = SimilarityIndex.tokens(@tickets.map(&:symptom_text).join(" ")).to_set
      scoped.to_a.sort_by { |a| -(SimilarityIndex.tokens("#{a.title} #{a.tags.join(' ')} #{a.body}").to_set & tokens).size }.first(4)
    end
  end

  def previous_resolutions
    TicketMessage.joins(:ticket).where(internal: false, author_type: "agent", tickets: { status: "resolved", product: product })
                 .where.not(ticket_id: @tickets.map(&:id)).order(created_at: :desc).limit(3).pluck(:body)
                 .map { |b| PiiScrubber.call(b, limit: 400) }
  end

  def prompt
    context =
      if @subject.is_a?(Incident)
        { incident: { title: @subject.title, summary: @subject.summary, suspected_root_cause: @subject.suspected_root_cause,
                      symptoms: @subject.symptoms, status: @subject.status, uncertainty: @subject.uncertainty } }
      else
        { ticket: { number: @subject.number, category: @subject.category, priority: @subject.priority } }
      end
    context.merge(
      product: Catalog::PRODUCTS[product],
      tickets: @tickets.map { |t| { ticket_number: t.number, status: t.status, text: PiiScrubber.call(t.symptom_text, limit: 450) } },
      knowledge_articles: articles.map { |a| { id: a.id, title: a.title, body: a.body.truncate(900) } },
      previous_resolutions: previous_resolutions
    ).to_json
  end

  def sanitize(data)
    numbers = @tickets.map(&:number)
    valid_articles = KnowledgeArticle.published.where(id: Array(data["article_ids"]).map(&:to_i)).to_a
    esc = data["internal_escalation"] || {}
    kb = data["kb_article"] || {}
    actions = Array(data["ticket_actions"]).select { |a| numbers.include?(a["ticket_number"]) }
    if @subject.is_a?(Incident)
      covered = actions.map { |a| a["ticket_number"] }
      actions += (numbers - covered).map { |n| { "ticket_number" => n, "action" => "reply_and_pending", "reason" => "Ortak yanıt ile bilgilendirme" } }
    else
      actions = []
    end
    {
      "troubleshooting_steps" => Array(data["troubleshooting_steps"]).map { |s| s.to_s.truncate(300) }.first(8),
      "customer_reply" => data["customer_reply"].to_s.truncate(3000),
      "internal_escalation" => { "needed" => !!esc["needed"], "team" => esc["team"].to_s.truncate(80), "summary" => esc["summary"].to_s.truncate(600) },
      "kb_gap" => !!data["kb_gap"],
      "kb_article" => { "title" => kb["title"].to_s.truncate(200), "body" => kb["body"].to_s.truncate(6000),
                        "tags" => Array(kb["tags"]).map { |t| t.to_s.truncate(30) }.first(8) },
      "ticket_actions" => actions.map { |a| a.slice("ticket_number", "action", "reason") },
      "articles" => valid_articles.map { |a| { "id" => a.id, "title" => a.title, "slug" => a.slug } },
      "product" => product
    }
  end

  def fallback_output
    steps = articles.flat_map(&:steps).first(5)
    steps = [ "Ürünü kullanmayı bırakın ve güvenli bir yerde bekletin.", "Bataryayı ve şarj cihazını oda sıcaklığında 1 saat bekletin." ] if steps.empty?
    {
      troubleshooting_steps: steps,
      customer_reply: "Merhaba {{musteri_adi}},\n\nBildiriminiz için teşekkür ederiz. Benzer bildirimleri birlikte inceliyoruz. " \
                      "Bu sırada şu adımları deneyebilirsiniz:\n#{steps.each_with_index.map { |s, i| "#{i + 1}. #{s}" }.join("\n")}\n\n" \
                      "Sorun devam ederse bu yanıta dönüş yapmanız yeterli.\n\nNorthforge Destek",
      internal_escalation: { needed: @subject.is_a?(Incident), team: "Kalite ekibi", summary: "Fallback modu: grup kalite ekibine iletilmeli." },
      kb_gap: articles.empty?,
      kb_article: { title: "Taslak: #{@subject.try(:title) || @subject.subject}", body: steps.each_with_index.map { |s, i| "#{i + 1}. #{s}" }.join("\n"), tags: [ "taslak" ] },
      ticket_actions: [],
      article_ids: articles.map(&:id).first(2)
    }
  end
end
