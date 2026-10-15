# Agent A: reads a new ticket and prepares category, priority, routing, relevant
# knowledge articles and a reply draft. Nothing is applied or sent until a
# person clicks "apply"; suggested IDs are validated against the database.
class TriageAgent
  URGENT_WORDS = %w[duman yanik kivilcim alev patla eridi isindi yaniyor yangin elektrik carpti].freeze
  HIGH_WORDS = %w[calismiyor calismaz bozuk acil sarj olmuyor durdu kirildi musteri bekliyor].freeze

  SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: %w[category priority team assignee_id reasoning evidence article_ids confidence draft_reply],
    properties: {
      category: { type: "string", enum: Catalog::CATEGORIES.keys },
      priority: { type: "string", enum: %w[low normal high urgent] },
      team: { type: "string", enum: Catalog::TEAMS.keys },
      assignee_id: { type: %w[integer null] },
      reasoning: { type: "string" },
      evidence: { type: "array", items: { type: "string" } },
      article_ids: { type: "array", items: { type: "integer" } },
      confidence: { type: "number" },
      draft_reply: { type: "string" }
    }
  }.freeze

  SYSTEM = <<~PROMPT.freeze
    Sen ResolveIQ'nun destek triage ajanısın. Northforge Tools adlı hayali bir elektrikli el aleti markasının
    müşteri destek ekibi için çalışıyorsun. Görevin: gelen ticket'ı okuyup kategori, öncelik, ekip ve sorumlu
    önermek, ilgili bilgi bankası makalelerini seçmek ve müşteriye gönderilebilecek kısa bir Türkçe yanıt taslağı yazmak.
    Kurallar:
    - Yalnızca verilen listelerdeki kategori, ekip, kullanıcı ID ve makale ID'lerini kullan. Uygun yoksa assignee_id null, article_ids boş olsun.
    - Güvenlik riski (duman, ısınma, yanık kokusu, kıvılcım) varsa öncelik "urgent" ve kategori "safety" olmalı; taslakta kullanımı durdurmasını söyle.
    - reasoning 2-3 cümle; evidence ticket metninden kısa alıntılar veya gözlemler.
    - confidence 0 ile 1 arasında; belirsizsen düşük ver.
    - draft_reply müşteriye hitap eden, nazik, en fazla 120 kelimelik bir taslak. Garanti/iade sözü verme, uydurma bilgi ekleme.
  PROMPT

  def self.call(ticket, user:)
    new(ticket, user).call
  end

  def initialize(ticket, user)
    @ticket = ticket
    @user = user
  end

  def call
    AgentRunner.call(agent_type: "triage", subject: @ticket, user: @user,
                     task: "ticket_triage", system: SYSTEM, prompt: prompt, schema: SCHEMA,
                     fallback: -> { fallback_output }) do |data|
      sanitize(data)
    end
  end

  private

  def agents
    @agents ||= User.agent.order(:id).to_a
  end

  def open_load
    @open_load ||= Ticket.unresolved.where(assignee_id: agents.map(&:id)).group(:assignee_id).count
  end

  def candidate_articles
    @candidate_articles ||= begin
      published = KnowledgeArticle.published.to_a
      query_tokens = SimilarityIndex.tokens(@ticket.symptom_text).to_set
      published.map do |a|
        overlap = SimilarityIndex.tokens("#{a.title} #{a.tags.join(' ')} #{a.excerpt(400)}").to_set & query_tokens
        score = overlap.size + (a.product.present? && a.product == @ticket.product ? 2 : 0)
        [ a, score ]
      end.select { |(_, s)| s.positive? }.sort_by { |(_, s)| -s }.first(5).map(&:first)
    end
  end

  def history_examples
    Ticket.resolved.where(product: @ticket.product).where.not(id: @ticket.id).order(resolved_at: :desc).limit(3)
  end

  def prompt
    {
      ticket: {
        subject: PiiScrubber.call(@ticket.subject, limit: 200),
        description: PiiScrubber.call(@ticket.description, limit: 1500),
        channel: @ticket.channel,
        product: @ticket.product_name,
        current_category: @ticket.category,
        current_priority: @ticket.priority
      },
      categories: Catalog::CATEGORIES,
      teams: Catalog::TEAMS,
      agents: agents.map { |a| { id: a.id, team: a.team, open_tickets: open_load[a.id].to_i } },
      knowledge_articles: candidate_articles.map { |a| { id: a.id, title: a.title, summary: a.excerpt(240) } },
      resolved_examples: history_examples.map { |t| { subject: PiiScrubber.call(t.subject, limit: 160), category: t.category, priority: t.priority } }
    }.to_json
  end

  # Drop anything that does not refer to an existing, allowed record.
  def sanitize(data)
    dropped = []
    category = Catalog::CATEGORIES.key?(data["category"]) ? data["category"] : (dropped << "category" && nil)
    priority = Ticket.priorities.key?(data["priority"]) ? data["priority"] : (dropped << "priority" && nil)
    team = Catalog::TEAMS.key?(data["team"]) ? data["team"] : nil

    assignee = agents.find { |a| a.id == data["assignee_id"].to_i } if data["assignee_id"].present?
    dropped << "assignee_id:#{data['assignee_id']}" if data["assignee_id"].present? && assignee.nil?

    valid_articles = KnowledgeArticle.published.where(id: Array(data["article_ids"]).map(&:to_i)).to_a
    invalid_ids = Array(data["article_ids"]).map(&:to_i) - valid_articles.map(&:id)
    dropped.concat(invalid_ids.map { |id| "article_id:#{id}" })

    {
      "category" => category,
      "category_name" => Catalog::CATEGORIES[category],
      "priority" => priority,
      "team" => team,
      "team_name" => Catalog::TEAMS[team],
      "assignee_id" => assignee&.id,
      "assignee_name" => assignee&.name,
      "reasoning" => data["reasoning"].to_s.truncate(800),
      "evidence" => Array(data["evidence"]).map { |e| e.to_s.truncate(200) }.first(5),
      "articles" => valid_articles.map { |a| { "id" => a.id, "title" => a.title, "slug" => a.slug } },
      "confidence" => data["confidence"].to_f.clamp(0.0, 1.0).round(2),
      "draft_reply" => data["draft_reply"].to_s.truncate(2000),
      "dropped_suggestions" => dropped
    }
  end

  FALLBACK_CATEGORY_RULES = [
    [ "battery_charging", /sarj|batarya|aku|led/ ],
    [ "warranty", /garanti|iade|degisim|fatura/ ],
    [ "order_shipping", /kargo|siparis|teslim/ ],
    [ "spare_parts", /parca|yedek|komur|disk/ ],
    [ "usage_howto", /nasil|kullan|ayar/ ]
  ].freeze

  def fallback_output
    folded = @ticket.symptom_text.downcase(:turkic).gsub(/[çğıöşü]/, SimilarityIndex::FOLD)
    evidence = []
    urgent_hits = URGENT_WORDS.select { |w| folded.include?(w) }
    high_hits = HIGH_WORDS.select { |w| folded.include?(w) }

    category =
      if urgent_hits.any?
        evidence << "Güvenlik anahtar kelimesi: #{urgent_hits.join(', ')}"
        "safety"
      elsif (rule = FALLBACK_CATEGORY_RULES.find { |_, re| folded.match?(re) })
        evidence << "Kategori anahtar kelimesi: #{folded.scan(rule.last).uniq.join(', ')}"
        rule.first
      else
        evidence << "Anahtar kelime eşleşmedi; mevcut kategori korundu"
        @ticket.category || "product_defect"
      end
    priority =
      if urgent_hits.any? then "urgent"
      elsif high_hits.any?
        evidence << "Öncelik anahtar kelimesi: #{high_hits.join(', ')}"
        "high"
      else "normal"
      end
    team = Catalog::CATEGORY_TEAM[category]
    assignee = agents.select { |a| a.team == team }.min_by { |a| open_load[a.id].to_i } || agents.min_by { |a| open_load[a.id].to_i }
    evidence << "Sorumlu: #{Catalog::TEAMS[team]} içinde en az açık ticket'ı olan uzman" if assignee
    {
      category: category, priority: priority, team: team, assignee_id: assignee&.id,
      reasoning: "Deterministik kural tabanlı fallback: anahtar kelimelere göre sınıflandırıldı (LLM çağrısı yapılmadı).",
      evidence: evidence,
      article_ids: candidate_articles.first(2).map(&:id),
      confidence: 0.4,
      draft_reply: "Merhaba #{@ticket.customer.first_name}, talebinizi aldık. Ekibimiz konuyu inceliyor; " \
                   "bu sırada ilgili bilgi bankası adımlarını paylaşıyoruz. En kısa sürede size dönüş yapacağız."
    }
  end
end
