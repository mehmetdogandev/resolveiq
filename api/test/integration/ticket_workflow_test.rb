require "test_helper"

class TicketWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    seed!
    login_as agent_email
  end

  test "create, assign, reply, add internal note, resolve and read back after reload" do
    customer = Customer.first
    api_post "/tickets", params: { ticket: { subject: "VC-20 tetik takılıyor", description: "Tetik basılı kalıyor ve geri gelmiyor.",
                                             customer_id: customer.id, channel: "web", priority: "high", category: "product_defect", product: "vc20_drill" } }
    assert_response :created
    id = json.dig("ticket", "id")
    assert_match(/\ARIQ-\d+\z/, json.dig("ticket", "number"))

    api_get "/tickets", params: nil
    assert_includes json["tickets"].map { |t| t["id"] }, id

    emre = User.find_by!(email: "emre@resolveiq.demo")
    api_patch "/tickets/#{id}", params: { ticket: { assignee_id: emre.id, status: "in_progress", priority: "urgent" } }
    assert_response :ok
    assert_equal emre.id, json.dig("ticket", "assignee", "id")
    assert_equal "urgent", json.dig("ticket", "priority")

    api_post "/tickets/#{id}/messages", params: { message: { body: "Merhaba, tetik yayını kontrol edelim.", internal: false } }
    assert_response :created
    api_post "/tickets/#{id}/messages", params: { message: { body: "Müşteri kurumsal, öncelikli takip.", internal: true } }
    assert_response :created

    api_post "/tickets/#{id}/resolve"
    assert_response :ok
    assert_equal "resolved", json.dig("ticket", "status")

    api_get "/tickets/#{id}"
    t = json["ticket"]
    assert_equal "resolved", t["status"]
    assert t["resolved_at"].present?
    assert t["first_response_at"].present?
    assert_equal [ false, false, true ], t["messages"].map { |m| m["internal"] }
    assert_equal %w[customer agent agent], t["messages"].map { |m| m["author_type"] }
    actions = AuditLog.for_target(Ticket.find(id)).pluck(:action)
    assert_includes actions, "ticket.created"
    assert_includes actions, "ticket.reply_sent"
    assert_includes actions, "ticket.internal_note_added"
    assert_includes actions, "ticket.resolved"

    api_post "/tickets/#{id}/reopen"
    assert_equal "open", json.dig("ticket", "status")
    assert_nil json.dig("ticket", "resolved_at")
  end

  test "invalid ticket returns 422 with field details" do
    api_post "/tickets", params: { ticket: { subject: "", description: "", channel: "fax" } }
    assert_response :unprocessable_content
    assert_equal "validation_failed", json["code"]
    assert json["details"].key?("subject")
    assert json["details"].key?("channel")
  end

  test "unknown ticket returns 404" do
    api_get "/tickets/999999"
    assert_response :not_found
  end

  test "invalid status update returns 422" do
    api_patch "/tickets/#{ticket('vc20-noise').id}", params: { ticket: { status: "archived" } }
    assert_response :unprocessable_content
  end

  test "inbox filters persisted tickets by channel, status and priority" do
    api_get "/tickets?channel=chat"
    assert_response :ok
    assert json["tickets"].any?
    assert json["tickets"].all? { |t| t["channel"] == "chat" }
    assert_equal Ticket.via_chat.count, json.dig("meta", "total")

    api_get "/tickets?channel=email,web&status=open&priority=high,urgent"
    expected = Ticket.where(channel: %w[email web], status: "open", priority: %w[high urgent]).pluck(:id).sort
    assert_equal expected, json["tickets"].map { |t| t["id"] }.sort

    api_get "/tickets?q=#{CGI.escape('kırmızı')}"
    assert json["tickets"].map { |t| t["subject"] }.any? { |s| s.include?("kırmızı") }

    api_get "/tickets?assignee_id=none&open_only=true"
    assert json["tickets"].all? { |t| t["assignee"].nil? && t["status"] != "resolved" }
  end

  test "customer history lists the customer's tickets" do
    customer = ticket("pc5-cold-1").customer
    api_get "/customers/#{customer.id}"
    assert_response :ok
    assert_equal customer.tickets.count, json["tickets"].size
    assert_equal customer.tickets.count, json.dig("customer", "stats", "total")
  end

  test "ticket detail exposes related tickets without calling an LLM" do
    api_get "/tickets/#{ticket('pc5-cold-6').id}"
    refs = json.dig("ticket", "similar_tickets").map { |t| Ticket.find(t["id"]).external_ref }
    assert refs.all? { |r| r.start_with?("pc5-") }
    assert_includes refs, "pc5-cold-1"
    assert_equal 0, AgentRun.count
  end

  test "dashboard metrics are computed from the database" do
    api_get "/dashboard"
    assert_response :ok
    assert_equal Ticket.unresolved.count, json.dig("totals", "open")
    assert_equal Ticket.resolved.count, json.dig("totals", "resolved")
    assert_equal true, json["synthetic_data"]
  end
end
