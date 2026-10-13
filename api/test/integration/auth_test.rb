require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  setup { seed! }

  test "login sets an HttpOnly session cookie and /me returns the user" do
    login_as manager_email

    cookie = Array(response.headers["Set-Cookie"]).join("\n")
    assert_match(/resolveiq_session=/, cookie)
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=lax/i, cookie)
    refute_includes response.body, "password"

    api_get "/me"
    assert_response :ok
    assert_equal "manager", json.dig("user", "role")
  end

  test "only a digest of the session token is stored" do
    login_as agent_email
    raw = cookies[:resolveiq_session]
    assert raw.present?
    refute Session.exists?(token_digest: raw)
    assert Session.exists?(token_digest: Session.digest(raw))
  end

  test "wrong password returns 401 with a JSON error" do
    api_post "/auth/login", params: { email: manager_email, password: "wrong-password" }
    assert_response :unauthorized
    assert_equal "invalid_credentials", json["code"]
  end

  test "protected endpoints require a session" do
    api_get "/tickets"
    assert_response :unauthorized
    assert_equal "unauthenticated", json["code"]
  end

  test "logout destroys the session" do
    login_as agent_email
    api_delete "/auth/logout"
    assert_response :no_content

    api_get "/me"
    assert_response :unauthorized
  end

  test "state-changing requests from a foreign origin are rejected" do
    login_as agent_email
    post "/api/v1/tickets/#{ticket('pc5-cold-1').id}/resolve", headers: { "Origin" => "https://evil.example" }
    assert_response :forbidden
    assert_equal "bad_origin", json["code"]
  end

  test "missing parameters return 400" do
    api_post "/auth/login", params: { email: manager_email }
    assert_response :bad_request
  end

  test "demo reset requires the admin token" do
    previous = ENV["ADMIN_TOKEN"]
    ENV["ADMIN_TOKEN"] = "test-admin-token"
    Ticket.first.update!(subject: "Değiştirilmiş konu")

    post "/api/v1/admin/demo_reset", headers: { "X-Admin-Token" => "wrong" }
    assert_response :unauthorized

    post "/api/v1/admin/demo_reset", headers: { "X-Admin-Token" => "test-admin-token" }
    assert_response :ok
    assert_equal 22, json["tickets"]
    refute Ticket.exists?(subject: "Değiştirilmiş konu")
    assert_equal "RIQ-1001", Ticket.order(:id).first.number, "reset restarts ticket numbering"
  ensure
    ENV["ADMIN_TOKEN"] = previous
  end
end
