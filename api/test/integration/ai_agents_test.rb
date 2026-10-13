require "test_helper"

class AiAgentsTest < ActionDispatch::IntegrationTest
  setup do
    seed!
    login_as agent_email
  end

  test "triage returns a validated recommendation and drops invalid IDs" do
    burak = User.find_by!(email: agent_email)
    article = KnowledgeArticle.published.find_by!(slug: "qc-2-sarj-cihazi-led-gostergeleri")
    draft = KnowledgeArticle.draft.first
    Llm.test_responder = lambda do |task, prompt|
      assert_equal "ticket_triage", task
      refute_includes prompt, "@example", "customer contact details must not reach the model"
      { category: "battery_charging", priority: "high", team: "battery", assignee_id: burak.id,
        reasoning: "Soğuk sonrası kırmızı LED.", evidence: [ "kırmızı ışık yanıp sönüyor" ],
        article_ids: [ article.id, draft.id, 987_654 ], confidence: 0.82, draft_reply: "Merhaba, bataryayı ısıtıp deneyin." }
    end

    t = ticket("pc5-cold-6")
    api_post "/tickets/#{t.id}/triage"
    assert_response :created
    run = json["run"]
    assert_equal "succeeded", run["status"]
    assert_equal "fake", run["source"]
    assert_equal [ article.id ], run.dig("output", "articles").map { |a| a["id"] }
    assert_includes run.dig("output", "dropped_suggestions"), "article_id:987654"
    assert_includes run.dig("output", "dropped_suggestions"), "article_id:#{draft.id}"
    assert_equal burak.id, run.dig("output", "assignee_id")

    api_post "/tickets/#{t.id}/triage/apply", params: { run_id: run["id"], fields: %w[category priority assignee] }
    assert_response :ok
    t.reload
    assert_equal "battery_charging", t.category
    assert_equal "high", t.priority
    assert_equal burak.id, t.assignee_id
    assert_includes t.article_ids, article.id
    assert_equal 1, t.messages.count, "triage must never send a customer message"
    assert AgentRun.find(run["id"]).applied_at.present?
    assert AuditLog.exists?(action: "ticket.triage_applied", target_id: t.id)
  end

  test "triage rejects an assignee that is not an agent" do
    manager = User.find_by!(email: manager_email)
    Llm.test_responder = ->(*) { { category: "warranty", priority: "low", team: "warranty", assignee_id: manager.id, reasoning: "", evidence: [], article_ids: [], confidence: 0.5, draft_reply: "" } }
    api_post "/tickets/#{ticket('pc5-crack').id}/triage"
    assert_nil json.dig("run", "output", "assignee_id")
    assert_includes json.dig("run", "output", "dropped_suggestions"), "assignee_id:#{manager.id}"
  end

  test "provider failure returns 502 and records a failed run" do
    Llm.test_responder = ->(*) { Llm::Error.new("timeout") }
    api_post "/tickets/#{ticket('pc5-cold-1').id}/triage"
    assert_response :bad_gateway
    assert_equal "ai_error", json["code"]
    assert_equal "failed", AgentRun.last.status
  end

  test "unconfigured provider returns 503 with setup instructions" do
    with_stub(Llm, :mode, -> { "unavailable" }) do
      api_post "/tickets/#{ticket('pc5-cold-1').id}/triage"
    end
    assert_response :service_unavailable
    assert_equal "ai_unavailable", json["code"]
    assert_match(/OPENAI_API_KEY/, json["error"])
  end

  test "labeled fallback triage explains its keyword rules and costs nothing" do
    with_stub(Llm, :mode, -> { "fallback" }) do
      api_post "/tickets/#{ticket('pc5-cold-6').id}/triage"
    end
    assert_response :created
    run = json["run"]
    assert_equal "fallback", run["source"]
    assert_equal 0, run["cost_usd"].to_f
    assert_equal "battery_charging", run.dig("output", "category")
    assert run.dig("output", "evidence").any? { |e| e.start_with?("Kategori anahtar kelimesi") }
  end

  test "pattern detection groups the six similar tickets and ignores unrelated controls" do
    Llm.test_responder = lambda do |task, prompt|
      assert_equal "pattern_detection", task
      payload = JSON.parse(prompt)
      numbers = payload["tickets"].map { |t| t["ticket_number"] }
      refute_match(/Kerem|Hakan|@example/, prompt)
      { title: "PC-5 soğukta şarj olmuyor", summary: "Soğukta bekleyen bataryalar kırmızı LED veriyor.",
        symptoms: [ "kırmızı LED yanıp sönüyor" ], suspected_root_cause: "Olası: düşük sıcaklık koruması.",
        evidence: numbers.map { |n| { ticket_number: n, observation: "soğuk sonrası" } } + [ { ticket_number: "RIQ-0", observation: "uydurma" } ],
        confidence: 0.7, uncertainty: "Parti bilgisi doğrulanmadı.", severity: "high",
        recommended_next_action: "Kalite ekibine ilet.", suggested_actions: [ "Ortak yanıt gönder" ], unrelated_ticket_numbers: [] }
    end

    api_post "/ai/pattern_scan"
    assert_response :ok
    assert_equal 1, json["proposals"].size
    incident = Incident.find(json.dig("proposals", 0, "incident", "id"))
    assert incident.proposed?
    expected = %w[pc5-cold-1 pc5-cold-2 pc5-cold-3 pc5-cold-4 pc5-cold-5 pc5-cold-6].map { |r| ticket(r).id }.sort
    assert_equal expected, incident.ticket_ids.sort
    %w[pc5-crack pc5-runtime pc5-gauge vc20-noise].each { |r| refute_includes incident.ticket_ids, ticket(r).id }
    refute incident.evidence.any? { |e| e["ticket_number"] == "RIQ-0" }, "evidence must reference real group members"
    assert_equal 6, incident.affected_customers
    assert_operator json.dig("proposals", 0, "run", "tokens_in"), :>, 0
    assert Ticket.where(id: expected).all? { |t| t.messages.count == t.messages.where(origin: "manual").count }

    api_post "/ai/pattern_scan"
    assert_equal 0, json["proposals"].size, "tickets already in an active incident are not re-proposed"
  end

  test "model can exclude a member it judges unrelated" do
    Llm.test_responder = lambda do |_task, prompt|
      numbers = JSON.parse(prompt)["tickets"].map { |t| t["ticket_number"] }
      { title: "x", summary: "x", symptoms: [], suspected_root_cause: "x", evidence: [], confidence: 0.5, uncertainty: "x",
        severity: "medium", recommended_next_action: "x", suggested_actions: [], unrelated_ticket_numbers: [ numbers.last ] }
    end
    api_post "/ai/pattern_scan"
    assert_equal 5, Incident.last.tickets.count
  end

  test "resolution: prepare, manager confirms and applies the shared reply to selected tickets" do
    incident = Incident.create!(title: "PC-5 soğuk şarj", summary: "Grup", status: "proposed", product: "pc5_battery")
    refs = %w[pc5-cold-1 pc5-cold-2 pc5-cold-4]
    refs.each { |r| incident.incident_tickets.create!(ticket: ticket(r)) }

    Llm.test_responder = lambda do |task, prompt|
      assert_equal "resolution_plan", task
      numbers = JSON.parse(prompt)["tickets"].map { |t| t["ticket_number"] }
      { troubleshooting_steps: [ "Bataryayı oda sıcaklığında 1 saat bekletin" ],
        customer_reply: "Merhaba {{musteri_adi}}, bataryayı oda sıcaklığında bekletip tekrar deneyin.",
        internal_escalation: { needed: true, team: "Kalite", summary: "Soğuk koruması" },
        kb_gap: true, kb_article: { title: "PC-5 soğukta şarj", body: "1. Isıt\n2. Tak", tags: [ "soğuk" ] },
        ticket_actions: numbers.map { |n| { ticket_number: n, action: "reply_and_pending", reason: "ortak" } } + [ { ticket_number: "RIQ-1", action: "reply_and_resolve", reason: "yok" } ],
        article_ids: [] }
    end

    api_post "/incidents/#{incident.id}/prepare_resolution"
    assert_response :created
    plan = json.dig("incident", "resolution_plan")
    assert_equal true, plan["kb_gap"]
    refute plan["ticket_actions"].any? { |a| a["ticket_number"] == "RIQ-1" }

    api_post "/incidents/#{incident.id}/apply_resolution", params: { reply_body: plan["customer_reply"], ticket_ids: incident.ticket_ids, status: "pending" }
    assert_response :forbidden, "agents cannot run bulk incident actions"

    api_delete "/auth/logout"
    login_as manager_email
    api_post "/incidents/#{incident.id}/apply_resolution", params: { reply_body: plan["customer_reply"], ticket_ids: incident.ticket_ids, status: "pending" }
    assert_response :bad_request, "incident must be confirmed first"

    api_post "/incidents/#{incident.id}/confirm"
    assert_response :ok
    selected = [ ticket("pc5-cold-1").id, ticket("pc5-cold-2").id ]
    api_post "/incidents/#{incident.id}/apply_resolution",
             params: { reply_body: plan["customer_reply"], ticket_ids: selected, status: "pending", internal_note: "Kalite ekibine iletildi" }
    assert_response :ok

    t1 = ticket("pc5-cold-1")
    assert_equal "pending", t1.status
    last_public = t1.messages.where(internal: false).last
    assert_equal "incident", last_public.origin
    assert_includes last_public.body, t1.customer.first_name
    refute_includes last_public.body, "{{musteri_adi}}"
    assert t1.messages.where(internal: true).exists?
    assert_equal "open", ticket("pc5-cold-4").status, "unselected tickets are untouched"
    assert AuditLog.exists?(action: "incident.resolution_applied", target_id: incident.id)

    api_post "/incidents/#{incident.id}/resolve", params: { note: "Soğuk koruması doğrulandı" }
    assert_equal "resolved", json.dig("incident", "status")
  end

  test "ticket-level resolution draft does not change the ticket" do
    Llm.test_responder = ->(*) { { troubleshooting_steps: [ "a" ], customer_reply: "Merhaba", internal_escalation: { needed: false, team: "", summary: "" },
                                   kb_gap: false, kb_article: { title: "", body: "", tags: [] }, ticket_actions: [], article_ids: [] } }
    t = ticket("vc20-noise")
    api_post "/tickets/#{t.id}/prepare_resolution"
    assert_response :created
    assert_equal "Merhaba", json.dig("run", "output", "customer_reply")
    assert_equal 1, t.messages.count
  end

  test "agent run history reports estimated cost totals" do
    Llm.test_responder = nil
    api_post "/tickets/#{ticket('vc20-noise').id}/triage"
    api_get "/agent_runs"
    assert_response :ok
    assert_equal 1, json["runs"].size
    assert_equal true, json["cost_is_estimate"]
    assert_equal 0.0, json["totals"].first["cost_usd"], "test doubles never accrue cost"
  end
end

class AiPricingTest < ActiveSupport::TestCase
  test "only real provider calls accrue estimated cost" do
    assert_equal BigDecimal("0.00045"), AiPricing.cost(tokens_in: 1000, tokens_out: 500, source: "openai")
    assert_equal 0, AiPricing.cost(tokens_in: 1000, tokens_out: 500, source: "fallback")
  end
end

class SimilarityIndexTest < ActiveSupport::TestCase
  test "shared-term evidence uses the words customers wrote, not stems" do
    forms = SimilarityIndex.surface_forms([ "Kırmızı ışık yanıp sönüyor", "kırmızı LED yanıp sönüyor" ])
    assert_equal "kırmızı", forms["kirmiz"]
    assert_equal "sönüyor", forms["sonuyo"]
  end
end

class DemoSeedTest < ActiveSupport::TestCase
  test "seeding twice does not duplicate records and seeds no AI results" do
    first = DemoSeed.run!
    second = DemoSeed.run!
    assert_equal first, second
    assert_equal 0, second[:agent_runs]
    assert_equal 0, second[:incidents]
  end
end
