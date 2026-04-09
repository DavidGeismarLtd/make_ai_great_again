class Organization < ApplicationRecord
  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :organization_invitations, dependent: :destroy
  has_many :api_configurations, dependent: :destroy
  has_one :organization_configuration, dependent: :destroy
  has_many :monitoring_api_keys, dependent: :destroy

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

    base_slug = name.parameterize
    candidate_slug = base_slug
    counter = 1

    # Keep trying until we find a unique slug
    while Organization.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
