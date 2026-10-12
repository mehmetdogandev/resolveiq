# FRONTEND_ORIGIN is a comma-separated list of allowed browser origins.
# Development and test fall back to the local Next.js dev server.
origins = ENV.fetch("FRONTEND_ORIGIN", "").split(",").map(&:strip).reject(&:empty?)

if origins.empty?
  if Rails.env.production?
    raise "FRONTEND_ORIGIN must be set in production (e.g. https://resolveiq.example.com)"
  end
  origins = [ "http://localhost:3000", "http://127.0.0.1:3000" ]
end

Rails.application.config.x.frontend_origins = origins.freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*origins)

    resource "/api/*",
      headers: :any,
      credentials: true,
      methods: %i[get post patch put delete options head],
      max_age: 600
  end
end
