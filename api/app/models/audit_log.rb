class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  # metadata must stay free of secrets and free-text customer content.
  def self.record!(actor:, action:, target: nil, metadata: {})
    create!(
      actor: actor,
      action: action,
      target_type: target&.class&.name,
      target_id: target&.id,
      metadata: metadata.to_h.deep_stringify_keys
    )
  end

  def self.for_target(target)
    where(target_type: target.class.name, target_id: target.id)
  end

  def as_api_json
    {
      id: id,
      action: action,
      actor_name: actor&.name || "Sistem",
      target_type: target_type,
      target_id: target_id,
      metadata: metadata,
      created_at: created_at
    }
  end
end
