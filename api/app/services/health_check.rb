# Readiness probe: the app is only "ok" when the database answers.
class HealthCheck
  APP_ID = "resolveiq-api".freeze

  Result = Struct.new(:healthy, :payload, keyword_init: true)

  def self.call
    new.call
  end

  def call
    database = database_status
    healthy = database == "ok"

    Result.new(
      healthy: healthy,
      payload: {
        status: healthy ? "ok" : "degraded",
        app: APP_ID,
        version: ENV.fetch("RENDER_GIT_COMMIT", "dev")[0, 7],
        environment: Rails.env,
        checks: { database: database },
        ai: { configured: Llm.configured?, mode: Llm.mode },
        time: Time.current.iso8601
      }
    )
  end

  private

  def database_status
    ActiveRecord::Base.connection_pool.with_connection { |conn| conn.select_value("SELECT 1") }
    "ok"
  rescue StandardError => e
    Rails.logger.error("[health] database check failed: #{e.class}")
    "unavailable"
  end
end
