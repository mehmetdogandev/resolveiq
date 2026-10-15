# Removes contact details before text is sent to the LLM. Customer names are
# never included in prompts in the first place.
module PiiScrubber
  EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i
  PHONE = /(?:\+?\d[\d\s().-]{8,}\d)/
  SERIAL = /\b(?:SN|S\/N|seri\s*no)[:\s#-]*[A-Z0-9-]{4,}\b/i

  module_function

  def call(text, limit: 600)
    text.to_s.gsub(EMAIL, "[e-posta]").gsub(PHONE, "[telefon]").gsub(SERIAL, "[seri-no]").squish.truncate(limit)
  end
end
