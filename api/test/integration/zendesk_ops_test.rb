require "test_helper"

class ZendeskOpsTest < ActionDispatch::IntegrationTest
  setup do
    seed!
    login_as agent_email
  end

  test "new ticket gets an SLA policy and due timestamps" do
    customer = Customer.first
    api_post "/tickets", params: { ticket: { subject: "QC-2 kablo ısısı", description: "Şarj kablosu ısınıyor.",
                                             customer_id: customer.id, channel: "email", priority: "urgent" } }
    assert_response :created
    sla = json.dig("ticket", "sla")
    assert_equal "Acil", sla["policy_name"]
    assert sla["first_response_due_at"].present?
    assert sla["resolution_due_at"].present?
    assert_equal "ok", sla["state"]
  end

  test "garanti keyword trigger assigns warranty team and tags" do
    customer = Customer.first
    api_post "/tickets", params: { ticket: { subject: "VC-20 iade ve garanti", description: "Garanti kapsamında değişim istiyorum.",
                                             customer_id: customer.id, channel: "web", priority: "normal" } }
    assert_response :created
    id = json.dig("ticket", "id")
    api_get "/tickets/#{id}"
    ticket = json["ticket"]
    assert_includes ticket["tags"], "garanti"
    assert_equal "warranty", ticket["category"]
    assert_equal "Ayşe Kara", ticket.dig("assignee", "name")
  end

  test "macro applies reply, tags and pending status" do
    id = ticket("pc5-cold-1").id
    macro = Macro.find_by!(name: "Batarya LED videosu iste")
    api_post "/tickets/#{id}/apply_macro", params: { macro_id: macro.id }
    assert_response :ok
    assert_equal "pending", json.dig("ticket", "status")
    assert_includes json.dig("ticket", "tags"), "bilgi-istendi"
    assert json.dig("ticket", "messages").any? { |m| m["body"].include?("LED") }
  end

  test "bulk update changes priority on selected tickets" do
    ids = Ticket.not_merged.unresolved.limit(2).pluck(:id)
    api_post "/tickets/bulk_update", params: { ids: ids, ticket: { priority: "high" } }
    assert_response :ok
    ids.each do |id|
      api_get "/tickets/#{id}"
      assert_equal "high", json.dig("ticket", "priority")
    end
  end

  test "merge moves messages onto the target and hides the source" do
    target = ticket("vc20-noise")
    source = ticket("drill-howto")
    source_messages = source.messages.count

    api_post "/tickets/#{target.id}/merge", params: { source_ids: [ source.id ] }
    assert_response :ok
    assert json.dig("ticket", "merged_tickets").any? { |t| t["id"] == source.id }

    api_get "/tickets?include_merged=true&q=#{source.number}"
    # source is merged so default inbox hides it
    api_get "/tickets?q=#{source.subject.split.first}"
    source.reload
    assert source.merged?
    assert_equal target.id, source.merged_into_id
    assert_operator target.reload.messages.count, :>=, source_messages
  end

  test "public help center lists published articles without login" do
    cookies.delete(:resolveiq_session)
    get "/api/v1/help/articles", headers: { "Accept" => "application/json" }
    assert_response :ok
    assert json["articles"].any?
    slug = json["articles"].first["slug"]
    get "/api/v1/help/articles/#{slug}", headers: { "Accept" => "application/json" }
    assert_response :ok
    assert json.dig("article", "body").present?
  end

  test "public web form creates a web ticket" do
    cookies.delete(:resolveiq_session)
    api_post "/help/requests", params: { request: { name: "Nihan Kaya", email: "nihan.kaya@example.com",
                                                    subject: "TB-22 kilit sorunu", description: "Çantanın kilidi kapanmıyor.",
                                                    product: "tb22_toolbox" } }
    assert_response :created
    assert_match(/\ARIQ-\d+\z/, json.dig("ticket", "number"))
    created = Ticket.find(json.dig("ticket", "id"))
    assert_equal "web", created.channel
    assert_equal "nihan.kaya@example.com", created.customer.email
  end

  test "csat can be recorded once on a resolved ticket" do
    customer = Customer.first
    api_post "/tickets", params: { ticket: { subject: "CSAT deneme", description: "Çözüldükten sonra puanlanacak.",
                                             customer_id: customer.id, channel: "web", priority: "low" } }
    resolved_id = json.dig("ticket", "id")
    api_post "/tickets/#{resolved_id}/resolve"
    api_post "/tickets/#{resolved_id}/csat", params: { score: 5, comment: "Hızlı çözüldü" }
    assert_response :created
    assert_equal 5, json.dig("csat", "score")

    api_post "/tickets/#{resolved_id}/csat", params: { score: 4 }
    assert_response :bad_request
  end

  test "reports include first reply, SLA and CSAT aggregates" do
    api_get "/reports"
    assert_response :ok
    assert json.dig("first_reply", "count").present?
    assert json.dig("sla").key?("met_rate")
    assert json.dig("csat", "count") >= 1
    assert json["by_agent"].any?
  end
end
