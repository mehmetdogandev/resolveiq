# Estimated cost per call. Prices (USD per 1M tokens) come from server-side env
# so they can be updated without a deploy; defaults are OpenAI's published
# gpt-4o-mini list prices. Real billing may differ, so the UI labels it "estimated".
module AiPricing
  module_function

  def input_per_million
    BigDecimal(ENV.fetch("OPENAI_PRICE_INPUT_PER_1M", "0.15"))
  end

  def output_per_million
    BigDecimal(ENV.fetch("OPENAI_PRICE_OUTPUT_PER_1M", "0.60"))
  end

  def cost(tokens_in:, tokens_out:, source:)
    return BigDecimal("0") unless source == "openai"

    ((tokens_in.to_i * input_per_million) + (tokens_out.to_i * output_per_million)) / 1_000_000
  end
end
