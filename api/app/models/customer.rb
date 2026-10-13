class Customer < ApplicationRecord
  has_many :tickets, dependent: :restrict_with_error

  enum :tier, { standard: "standard", pro: "pro", enterprise: "enterprise" }, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }

  scope :search, ->(q) {
    term = "%#{sanitize_sql_like(q.to_s.strip)}%"
    where("customers.name ILIKE :t OR customers.email ILIKE :t OR customers.company ILIKE :t", t: term)
  }

  def first_name
    name.split.first
  end

  def summary_json
    { id: id, name: name, email: email, company: company, tier: tier, city: city }
  end
end
