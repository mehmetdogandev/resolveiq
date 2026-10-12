require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Resolveiq
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Istanbul"
    config.i18n.default_locale = :tr
    config.i18n.available_locales = %i[tr en]

    config.api_only = true

    # Session token lives in an HttpOnly cookie, so the cookie middleware is needed in API mode.
    config.middleware.use ActionDispatch::Cookies

    config.active_job.queue_adapter = :async
  end
end
