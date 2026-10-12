require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "health reports ok with database check and app identifier" do
    get "/api/v1/health"

    assert_response :ok
    assert_equal "ok", json["status"]
    assert_equal "resolveiq-api", json["app"]
    assert_equal "ok", json.dig("checks", "database")
    assert_equal "application/json", response.media_type
  end

  test "health does not leak secrets or connection details" do
    get "/api/v1/health"

    body = response.body
    refute_match(/postgres(ql)?:\/\//i, body)
    refute_match(/password|secret|DATABASE_URL/i, body)
  end

  test "health returns 503 when the database is unreachable" do
    pool = ActiveRecord::Base.connection_pool
    with_stub(pool, :with_connection, ->(*) { raise ActiveRecord::ConnectionNotEstablished, "down" }) do
      get "/api/v1/health"
    end

    assert_response :service_unavailable
    assert_equal "degraded", json["status"]
    assert_equal "unavailable", json.dig("checks", "database")
  end

  test "liveness endpoint answers without the API namespace" do
    get "/up"
    assert_response :ok
  end

  test "CORS allows the configured frontend origin" do
    get "/api/v1/health", headers: { "Origin" => ORIGIN }

    assert_equal ORIGIN, response.headers["Access-Control-Allow-Origin"]
    assert_equal "true", response.headers["Access-Control-Allow-Credentials"]
  end

  test "CORS does not allow foreign origins" do
    get "/api/v1/health", headers: { "Origin" => "https://evil.example" }

    assert_nil response.headers["Access-Control-Allow-Origin"]
  end
end
