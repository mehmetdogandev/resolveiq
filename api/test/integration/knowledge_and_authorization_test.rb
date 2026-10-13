require "test_helper"

class KnowledgeAndAuthorizationTest < ActionDispatch::IntegrationTest
  setup { seed! }

  test "agent creates a draft, manager publishes it, it is searchable and linkable to a ticket" do
    login_as agent_email
    api_post "/articles", params: { article: { title: "PC-5 soğuk havada şarj", body: "1. Bataryayı ısıtın\n2. Tekrar takın",
                                               product: "pc5_battery", category: "battery_charging", tags: "soğuk, şarj" } }
    assert_response :created
    article_id = json.dig("article", "id")
    assert_equal "draft", json.dig("article", "status")
    assert_equal [ "soğuk", "şarj" ], json.dig("article", "tags")
    assert_equal [ "Bataryayı ısıtın", "Tekrar takın" ], json.dig("article", "steps")

    api_post "/articles/#{article_id}/publish"
    assert_response :forbidden

    t = ticket("pc5-cold-2")
    api_post "/tickets/#{t.id}/articles", params: { article_id: article_id }
    assert_response :forbidden, "draft articles cannot be linked"

    api_delete "/auth/logout"
    login_as manager_email
    api_post "/articles/#{article_id}/publish"
    assert_response :ok
    assert_equal "published", json.dig("article", "status")

    api_get "/articles?q=#{CGI.escape('soğuk')}"
    assert_includes json["articles"].map { |a| a["id"] }, article_id

    api_post "/tickets/#{t.id}/articles", params: { article_id: article_id }
    assert_response :created
    assert_includes json.dig("ticket", "articles").map { |a| a["id"] }, article_id
    assert AuditLog.exists?(action: "article.published", target_id: article_id)
    assert AuditLog.exists?(action: "ticket.article_linked", target_id: t.id)

    api_delete "/tickets/#{t.id}/articles/#{article_id}"
    assert_response :ok
    assert_empty json.dig("ticket", "articles").select { |a| a["id"] == article_id }
  end

  test "articles can be read by slug and filtered by product and category" do
    login_as agent_email
    api_get "/articles/qc-2-sarj-cihazi-led-gostergeleri"
    assert_response :ok
    assert_match(/kırmızı/, json.dig("article", "body"))

    api_get "/articles?product=pc5_battery&category=battery_charging"
    assert json["articles"].all? { |a| a["product"] == "pc5_battery" && a["category"] == "battery_charging" }
  end

  test "agents cannot edit published articles, see audit logs or manage incidents" do
    login_as agent_email
    published = KnowledgeArticle.published.first
    api_patch "/articles/#{published.id}", params: { article: { title: "Değişti" } }
    assert_response :forbidden

    api_get "/audit_logs"
    assert_response :forbidden

    incident = Incident.create!(title: "Test", summary: "Test", status: "proposed")
    api_post "/incidents/#{incident.id}/confirm"
    assert_response :forbidden
    assert incident.reload.proposed?
  end

  test "managers can read the audit log" do
    login_as manager_email
    api_get "/audit_logs"
    assert_response :ok
    assert json["audit_logs"].any? { |l| l["action"] == "session.login" }
  end
end
