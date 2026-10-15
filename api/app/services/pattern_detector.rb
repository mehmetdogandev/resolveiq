# Agent B: finds groups of similar recent tickets and proposes a hypothesis
# incident for each group.
#
# 1. Candidate filter: last 30 days, open or recently resolved, not already in an active incident.
# 2. Grouping (no LLM): same product + TF-IDF cosine >= CLUSTER_THRESHOLD, single-link,
#    then members with weak average similarity are pruned. Only groups of MIN_GROUP+ survive.
# 3. LLM: summarizes each group from scrubbed symptom text only (ticket numbers, no names
#    or contact details), proposes a possible cause, uncertainty and next action, and may
#    flag members that do not belong.
# 4. Safe persistence policy: the result is stored as an Incident with status "proposed".
#    A proposed incident changes no ticket and sends nothing; a manager must confirm it
#    before any bulk action is possible.
class PatternDetector
  CLUSTER_THRESHOLD = 0.30
  MIN_AVG_SIMILARITY = 0.22
  MIN_GROUP = 3
  MAX_GROUPS = 3

  SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: %w[title summary symptoms suspected_root_cause evidence confidence uncertainty severity recommended_next_action suggested_actions unrelated_ticket_numbers],
    properties: {
      title: { type: "string" },
      summary: { type: "string" },
      symptoms: { type: "array", items: { type: "string" } },
      suspected_root_cause: { type: "string" },
      evidence: {
        type: "array",
        items: {
          type: "object", additionalProperties: false, required: %w[ticket_number observation],
          properties: { ticket_number: { type: "string" }, observation: { type: "string" } }
        }
      },
      confidence: { type: "number" },
      uncertainty: { type: "string" },
      severity: { type: "string", enum: %w[low medium high critical] },
      recommended_next_action: { type: "string" },
      suggested_actions: { type: "array", items: { type: "string" } },
      unrelated_ticket_numbers: { type: "array", items: { type: "string" } }
    }
  }.freeze

  SYSTEM = <<~PROMPT.freeze
    Sen ResolveIQ'nun örüntü ve kök neden analiz ajanısın. Sana benzerlik algoritmasının aynı üründe
    bir araya getirdiği destek ticket'ları verilecek (yalnızca ticket numarası ve semptom metni).
    Görevin: ortak semptomları özetlemek, olası ortak nedeni HİPOTEZ olarak önermek ve belirsizliği açıkça yazmak.
    Kurallar:
    - Korelasyonu kanıtlanmış neden gibi sunma; "olası", "muhtemel" gibi ifadeler kullan.
    - evidence her ticket için metinden somut bir gözlem içersin; ticket_number verilenlerden biri olsun.
    - Gruba ait olmadığını düşündüğün ticket'ları unrelated_ticket_numbers içine yaz.
    - confidence 0-1 arası; az kanıt varsa düşük tut.
    - suggested_actions en fazla 4 kısa, uygulanabilir adım (ör. "ilgili lotu kalite ekibine eskale et").
    - Türkçe yaz, başlık en fazla 80 karakter.
  PROMPT

  Proposal = Struct.new(:incident, :run, :created, keyword_init: true)

  def self.call(user:)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    groups = candidate_groups
    proposals = groups.first(MAX_GROUPS).filter_map { |group| analyze(group) }
    { groups_found: groups.size, candidates_scanned: @candidate_count, proposals: proposals }
  end

  def candidate_groups
    linked = IncidentTicket.joins(:incident).merge(Incident.active).select(:ticket_id)
    tickets = SimilarityIndex.candidates(Ticket.includes(:customer)).where.not(id: linked).where.not(product: nil).to_a
    @candidate_count = tickets.size
    @index = SimilarityIndex.new(tickets)

    tickets.group_by(&:product).flat_map { |_, items| cluster(items) }
           .select { |g| g.size >= MIN_GROUP }
           .sort_by { |g| -g.size }
  end

  private

  def cluster(items)
    parent = items.to_h { |t| [ t.id, t.id ] }
    find = ->(x) { parent[x] == x ? x : (parent[x] = find.(parent[x])) }
    items.combination(2).each do |a, b|
      parent[find.(a.id)] = find.(b.id) if @index.similarity(a, b) >= CLUSTER_THRESHOLD
    end
    groups = items.group_by { |t| find.(t.id) }.values.select { |g| g.size >= MIN_GROUP }
    groups.map do |group|
      group.select do |t|
        others = group - [ t ]
        others.sum { |o| @index.similarity(t, o) } / others.size >= MIN_AVG_SIMILARITY
      end
    end
  end

  def analyze(group)
    shared = @index.shared_terms(group)
    run = AgentRunner.call(agent_type: "pattern_scan", subject: nil, user: @user,
                           task: "pattern_detection", system: SYSTEM, prompt: prompt(group, shared), schema: SCHEMA,
                           fallback: -> { fallback_output(group, shared) }) do |data|
      sanitize(data, group, shared)
    end

    members = group.select { |t| run.output["member_numbers"].include?(t.number) }
    return nil if members.size < MIN_GROUP

    persist(run, members)
  end

  def prompt(group, shared)
    {
      product: Catalog::PRODUCTS[group.first.product],
      shared_terms_from_similarity: shared,
      tickets: group.map do |t|
        { ticket_number: t.number, channel: t.channel, status: t.status, opened: t.created_at.to_date.iso8601,
          text: PiiScrubber.call(t.symptom_text, limit: 500) }
      end
    }.to_json
  end

  def sanitize(data, group, shared)
    numbers = group.map(&:number)
    unrelated = Array(data["unrelated_ticket_numbers"]) & numbers
    members = numbers - unrelated
    evidence = Array(data["evidence"]).select { |e| members.include?(e["ticket_number"]) }
                                      .map { |e| { "ticket_number" => e["ticket_number"], "observation" => e["observation"].to_s.truncate(240) } }
    {
      "title" => data["title"].to_s.truncate(120),
      "summary" => data["summary"].to_s.truncate(1200),
      "symptoms" => Array(data["symptoms"]).map { |s| s.to_s.truncate(160) }.first(6),
      "suspected_root_cause" => data["suspected_root_cause"].to_s.truncate(800),
      "evidence" => evidence,
      "confidence" => data["confidence"].to_f.clamp(0.0, 1.0).round(2),
      "uncertainty" => data["uncertainty"].to_s.truncate(600),
      "severity" => Incident.severities.key?(data["severity"]) ? data["severity"] : "medium",
      "recommended_next_action" => data["recommended_next_action"].to_s.truncate(400),
      "suggested_actions" => Array(data["suggested_actions"]).map { |s| s.to_s.truncate(200) }.first(4),
      "member_numbers" => members,
      "unrelated_ticket_numbers" => unrelated,
      "shared_terms" => shared,
      "product" => group.first.product
    }
  end

  def persist(run, members)
    out = run.output
    existing = Incident.proposed.where(product: out["product"]).find { |inc| (inc.ticket_ids & members.map(&:id)).size * 2 >= members.size }
    incident = existing || Incident.new
    created = incident.new_record?

    Incident.transaction do
      incident.update!(
        title: out["title"].presence || "Olası ortak sorun", summary: out["summary"].presence || "Benzer şikayetler gruplandı.",
        suspected_root_cause: out["suspected_root_cause"], severity: out["severity"], confidence: out["confidence"],
        uncertainty: out["uncertainty"], product: out["product"], symptoms: out["symptoms"],
        evidence: out["evidence"] + [ { "ticket_number" => "benzerlik", "observation" => "Ortak terimler: #{out['shared_terms'].join(', ')}" } ],
        suggested_actions: out["suggested_actions"], recommended_next_action: out["recommended_next_action"],
        detected_by_run: run, status: "proposed"
      )
      members.each do |t|
        link = incident.incident_tickets.find_or_initialize_by(ticket: t)
        link.update!(similarity: members.without(t).map { |o| @index.similarity(t, o) }.max.to_f.round(3))
      end
      run.update!(subject: incident)
      AuditLog.record!(actor: @user, action: created ? "incident.proposed" : "incident.proposal_refreshed", target: incident,
                       metadata: { agent_run_id: run.id, ticket_numbers: members.map(&:number), source: run.source })
    end
    Proposal.new(incident: incident, run: run, created: created)
  end

  def fallback_output(group, shared)
    {
      title: "Olası ortak sorun: #{Catalog::PRODUCTS[group.first.product]}",
      summary: "#{group.size} ticket benzer ifadeler içeriyor (#{shared.first(5).join(', ')}). Deterministik fallback; LLM özeti yok.",
      symptoms: shared.first(5),
      suspected_root_cause: "Belirlenemedi (fallback modu). Ortak terimler aynı ürün partisine veya kullanım koşuluna işaret edebilir.",
      evidence: group.map { |t| { ticket_number: t.number, observation: t.subject.truncate(120) } },
      confidence: 0.35,
      uncertainty: "Yalnızca kelime benzerliğine dayanır; neden-sonuç ilişkisi doğrulanmadı.",
      severity: group.size >= 5 ? "high" : "medium",
      recommended_next_action: "Grubu inceleyin, ilgisiz ticket'ları çıkarın ve kalite ekibine iletin.",
      suggested_actions: [ "Grubu incele ve onayla", "Kalite ekibine eskale et" ],
      unrelated_ticket_numbers: []
    }
  end
end
