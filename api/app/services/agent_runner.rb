# Wraps one LLM call: measures latency, records an AgentRun (success or failure)
# with tokens and estimated cost, and re-raises failures for the controller.
class AgentRunner
  def self.call(agent_type:, subject:, user:, **llm_args)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = Llm.complete(**llm_args)
    output = yield(result.data)

    AgentRun.create!(
      agent_type: agent_type, status: "succeeded", source: result.source, model: result.model,
      subject: subject, user: user, tokens_in: result.tokens_in, tokens_out: result.tokens_out,
      latency_ms: elapsed_ms(started), output: output, provider_request_id: result.request_id,
      cost_usd: AiPricing.cost(tokens_in: result.tokens_in, tokens_out: result.tokens_out, source: result.source)
    )
  rescue Llm::Error, Llm::Unavailable => e
    AgentRun.create!(
      agent_type: agent_type, status: "failed", source: Llm.mode == "unavailable" ? "none" : Llm.mode,
      model: Llm.mode == "openai" ? Llm.model : nil, subject: subject, user: user,
      latency_ms: elapsed_ms(started), error_summary: e.message.truncate(250)
    )
    raise
  end

  def self.elapsed_ms(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
  end
end
