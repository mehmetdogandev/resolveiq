class Macro < ApplicationRecord
  scope :active, -> { where(active: true).order(:name) }

  validates :name, presence: true, uniqueness: true
  validates :actions, presence: true

  def as_api_json
    { id: id, name: name, description: description, actions: actions }
  end
end
