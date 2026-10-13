class AgentRun < ApplicationRecord
  AGENT_TYPES = %w[triage pattern_scan resolution].freeze
  SOURCES = %w[openai fallback fake none].freeze

  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :user, optional: true
  belongs_to :applied_by, class_name: "User", optional: true

  validates :agent_type, inclusion: { in: AGENT_TYPES }
  validates :status, inclusion: { in: %w[succeeded failed] }
  validates :source, inclusion: { in: SOURCES }

  scope :succeeded, -> { where(status: "succeeded") }
  scope :recent, -> { order(created_at: :desc) }

  def succeeded?
    status == "succeeded"
  end

  def as_api_json
    {
      id: id,
      agent_type: agent_type,
      status: status,
      source: source,
      model: model,
      tokens_in: tokens_in,
      tokens_out: tokens_out,
      latency_ms: latency_ms,
      cost_usd: cost_usd.to_f,
      cost_is_estimate: true,
      output: output,
      error_summary: error_summary,
      provider_request_id: provider_request_id,
      subject_type: subject_type,
      subject_id: subject_id,
      user_name: user&.name,
      applied_at: applied_at,
      created_at: created_at
    }
  end
end
