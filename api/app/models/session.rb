class Session < ApplicationRecord
  TTL = 7.days

  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.start!(user, request)
    token = SecureRandom.urlsafe_base64(32)
    session = create!(
      user: user,
      token_digest: digest(token),
      expires_at: TTL.from_now,
      last_seen_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s.truncate(250)
    )
    [ session, token ]
  end

  def self.find_by_token(token)
    return nil if token.blank?

    active.includes(:user).find_by(token_digest: digest(token))
  end

  def touch_last_seen!
    update_column(:last_seen_at, Time.current) if last_seen_at.nil? || last_seen_at < 5.minutes.ago
  end
end
