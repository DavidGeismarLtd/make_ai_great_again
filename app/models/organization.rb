class Organization < ApplicationRecord
  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :api_configurations, dependent: :destroy
  has_one :organization_configuration, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  # Enums
  enum :status, { active: "active", inactive: "inactive" }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :active, -> { where(status: :active) }

  private

  def generate_slug
    return if slug.present?

    self.slug = name.parameterize
  end
end
