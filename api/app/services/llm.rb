# Provider-agnostic entry point for every LLM call. Keys never leave the server.
#
# Modes:
#   openai      - OPENAI_API_KEY is set; real provider requests.
#   fallback    - AI_DEMO_MODE=1 without a key; deterministic heuristics, labeled "fallback" in the UI.
#   fake        - test environment; controlled responses set via Llm.test_responder.
#   unavailable - nothing configured; AI endpoints answer 503 with setup instructions.
module Llm
  class Error < StandardError; end

  # Deliberately not a subclass of Error so controllers can map it to 503.
  class Unavailable < StandardError; end

  Result = Struct.new(:data, :model, :tokens_in, :tokens_out, :source, :request_id, keyword_init: true)

  UNAVAILABLE_MESSAGE = "AI katmanı yapılandırılmamış. Sunucuda OPENAI_API_KEY ortam değişkenini tanımlayın " \
                        "(veya açıkça etiketli deterministik demo için AI_DEMO_MODE=1).".freeze

  class << self
    attr_accessor :test_responder

    def mode
      return "fake" if Rails.env.test?
      return "openai" if api_key.present?
      return "fallback" if ENV["AI_DEMO_MODE"] == "1"

      "unavailable"
    end

    def configured?
      mode != "unavailable"
    end

    def model
      ENV.fetch("OPENAI_MODEL", "gpt-4o-mini")
    end

    # fallback: a lambda returning a Hash that matches the schema. Used only in
    # fallback/fake modes; never silently substituted for a failed real call.
    def complete(task:, system:, prompt:, schema:, fallback:)
      case mode
      when "openai"
        OpenaiClient.new(api_key: api_key, model: model).complete(system: system, user: prompt, schema: schema, schema_name: task)
      when "fallback"
        Result.new(data: fallback.call.deep_stringify_keys, model: "heuristic-fallback", tokens_in: 0, tokens_out: 0, source: "fallback")
      when "fake"
        data = test_responder ? test_responder.call(task, prompt) : fallback.call
        raise Error, data.message if data.is_a?(Exception)

        Result.new(data: data.deep_stringify_keys, model: "test-double", tokens_in: 120, tokens_out: 80, source: "fake")
      else
        raise Unavailable, UNAVAILABLE_MESSAGE
      end
    end

    private

    def api_key
      ENV["OPENAI_API_KEY"]
    end
  end
end
