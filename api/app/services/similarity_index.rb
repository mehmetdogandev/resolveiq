# Transparent, dependency-free text similarity: Turkish-aware normalization,
# crude prefix stemming and TF-IDF cosine similarity over ticket symptom text.
# Used for "related tickets" and as the candidate filter before the LLM ever
# sees a ticket group.
class SimilarityIndex
  WINDOW = 30.days
  RELATED_THRESHOLD = 0.22
  LINK_THRESHOLD = 0.30
  STEM_LENGTH = 6

  STOPWORDS = %w[
    ve ile bir bu su da de cok ama icin gibi daha olan var yok ben biz siz mi mu ne ki her hic sonra once kadar
    artik merhaba iyi gunler tesekkur tesekkurler rica lutfen urun urunu aldim aldik yardim etmek oldu olur ediyor
    ediyorum sey hala bile sadece tekrar nasil neden durum sorun problem rahmen olarak oluyor olmuyor yapti yaptim
    yapiyor bana bize sizin benim bizim icinde uzerinde kez gun hafta ay yeni eski tam hemen acaba sanirim dogru
    ancak fakat veya yada ise eger cunku bunu buna simdi bugun dun yine hep cok
  ].to_set.freeze

  FOLD = { "ç" => "c", "ğ" => "g", "ı" => "i", "ö" => "o", "ş" => "s", "ü" => "u", "â" => "a", "î" => "i", "û" => "u" }.freeze

  def self.tokens(text)
    text.to_s.downcase(:turkic).gsub(/[çğıöşüâîû]/, FOLD).gsub(/[^a-z0-9]+/, " ").split
        .reject { |w| w.length < 3 || STOPWORDS.include?(w) || w.match?(/\A\d+\z/) }
        .map { |w| w[0, STEM_LENGTH] }
  end

  def self.candidates(scope = Ticket.all)
    scope.where("tickets.created_at >= ?", WINDOW.ago)
         .where("tickets.status <> 'resolved' OR tickets.resolved_at >= ?", WINDOW.ago)
  end

  # Tickets most similar to +ticket+ (same product when known), best first.
  def self.similar_to(ticket, limit: 5, threshold: RELATED_THRESHOLD)
    scope = candidates(Ticket.includes(:customer, :assignee)).where.not(id: ticket.id)
    scope = scope.where(product: ticket.product) if ticket.product.present?
    pool = scope.limit(300).to_a
    return [] if pool.empty?

    index = new(pool + [ ticket ])
    pool.map { |other| [ other, index.similarity(ticket, other) ] }
        .select { |(_, score)| score >= threshold }
        .sort_by { |(_, score)| -score }
        .first(limit)
  end

  def self.max_similarity(ticket, others)
    others = others.reject { |o| o.id == ticket.id }
    return 0.0 if others.empty?

    index = new(others + [ ticket ])
    others.map { |o| index.similarity(ticket, o) }.max
  end

  def initialize(tickets)
    @vectors = {}
    docs = tickets.uniq(&:id).to_h { |t| [ t.id, self.class.tokens(t.symptom_text) ] }
    df = Hash.new(0)
    docs.each_value { |toks| toks.uniq.each { |tok| df[tok] += 1 } }
    n = docs.size.to_f
    @idf = df.transform_values { |count| Math.log((n + 1) / (count + 1)) + 1 }
    docs.each do |id, toks|
      tf = toks.tally
      vec = tf.to_h { |tok, count| [ tok, (1 + Math.log(count)) * @idf[tok] ] }
      norm = Math.sqrt(vec.values.sum { |v| v * v })
      @vectors[id] = norm.zero? ? {} : vec.transform_values { |v| v / norm }
    end
  end

  def similarity(a, b)
    va = @vectors[a.id] || {}
    vb = @vectors[b.id] || {}
    small, large = va.size < vb.size ? [ va, vb ] : [ vb, va ]
    small.sum { |tok, w| w * (large[tok] || 0) }
  end

  # Highest-weighted shared terms across a group; shown as transparent evidence.
  def shared_terms(tickets, limit: 8)
    counts = Hash.new(0)
    tickets.each { |t| (@vectors[t.id] || {}).each_key { |tok| counts[tok] += 1 } }
    min_share = [ (tickets.size * 0.5).ceil, 2 ].max
    stems = counts.select { |_, c| c >= min_share }.sort_by { |tok, c| [ -c, -@idf[tok].to_f ] }.first(limit).map(&:first)
    surface = self.class.surface_forms(tickets.map(&:symptom_text))
    stems.map { |stem| surface[stem] || stem }
  end

  # Maps each stem to the word customers most often actually wrote for it.
  def self.surface_forms(texts)
    forms = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    texts.each do |text|
      text.to_s.downcase(:turkic).scan(/[[:alnum:]]+/).each do |word|
        stem = tokens(word).first
        forms[stem][word] += 1 if stem
      end
    end
    forms.transform_values { |words| words.max_by { |word, count| [ count, -word.length ] }.first }
  end
end
