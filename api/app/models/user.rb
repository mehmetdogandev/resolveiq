class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :delete_all
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, inverse_of: :assignee, dependent: :nullify

  enum :role, { manager: "manager", agent: "agent" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :team, inclusion: { in: Catalog::TEAMS.keys }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def initials
    name.split.map { |part| part[0] }.first(2).join.upcase
  end

  def summary_json
    { id: id, name: name, role: role, team: team, team_name: Catalog::TEAMS[team], title: title, initials: initials }
  end

  def me_json
    summary_json.merge(email: email)
  end
end
