require "net/http"

module Llm
  # Chat Completions with Structured Outputs (strict JSON schema).
  class OpenaiClient
    ENDPOINT = URI("https://api.openai.com/v1/chat/completions")
    MAX_RETRIES = 2
    RETRYABLE = [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError, OpenSSL::SSL::SSLError ].freeze

    attr_reader :model

    def initialize(api_key:, model:)
      @api_key = api_key
      @model = model
    end

    def complete(system:, user:, schema:, schema_name:)
      payload = {
        model: model,
        temperature: 0.2,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user }
        ],
        response_format: {
          type: "json_schema",
          json_schema: { name: schema_name, strict: true, schema: schema }
        }
      }

      response = with_retries { post(payload) }
      body = parse(response.body)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "OpenAI #{response.code}: #{body.dig('error', 'message').to_s.truncate(200)}"
      end

      message = body.dig("choices", 0, "message") || {}
      raise Error, "Model isteği reddetti: #{message['refusal']}" if message["refusal"].present?

      Result.new(
        data: parse(message["content"].to_s),
        model: body["model"] || model,
        tokens_in: body.dig("usage", "prompt_tokens").to_i,
        tokens_out: body.dig("usage", "completion_tokens").to_i,
        source: "openai",
        request_id: response["x-request-id"] || body["id"]
      )
    end

    private

    def with_retries
      attempts = 0
      begin
        attempts += 1
        response = yield
        if retryable_status?(response) && attempts <= MAX_RETRIES
          sleep(backoff(attempts))
          raise RetrySignal
        end
        response
      rescue RetrySignal
        retry
      rescue *RETRYABLE => e
        raise Error, "Sağlayıcıya ulaşılamadı (#{e.class.name.demodulize})" if attempts > MAX_RETRIES

        sleep(backoff(attempts))
        retry
      end
    end

    class RetrySignal < StandardError; end

    def retryable_status?(response)
      code = response.code.to_i
      code == 429 || code >= 500
    end

    def backoff(attempt)
      Rails.env.test? ? 0 : 0.6 * attempt
    end

    def parse(raw)
      JSON.parse(raw)
    rescue JSON::ParserError
      raise Error, "Sağlayıcıdan geçersiz JSON yanıtı alındı"
    end

    def post(payload)
      http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = Integer(ENV.fetch("OPENAI_TIMEOUT_SECONDS", 30))
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json
      http.request(request)
    end
  end
end
