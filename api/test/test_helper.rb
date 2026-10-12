ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    teardown { Llm.test_responder = nil }

    # Minitest 6 ships without Object#stub; this temporarily overrides one method on one object.
    def with_stub(object, method_name, implementation)
      object.define_singleton_method(method_name, implementation)
      yield
    ensure
      object.singleton_class.send(:remove_method, method_name)
    end
  end
end

class ActionDispatch::IntegrationTest
  ORIGIN = "http://localhost:3000".freeze

  def json
    JSON.parse(response.body)
  end

  def default_headers
    { "Origin" => ORIGIN, "Accept" => "application/json" }
  end

  %i[get post patch delete].each do |verb|
    define_method("api_#{verb}") do |path, params: nil, headers: {}|
      send(verb, "/api/v1#{path}", params: params&.to_json, headers: default_headers.merge("Content-Type" => "application/json").merge(headers))
    end
  end
end
