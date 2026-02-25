class OrganizationMembership < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization

  # Note: acts_as_tenant automatically adds:
  # - belongs_to :organization
  # - default_scope to filter by current tenant
  # - validation to prevent cross-tenant associations

  # Associations
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :role, presence: true, inclusion: { in: %w[viewer member admin owner] }

  # Enums
  enum :role, { viewer: "viewer", member: "member", admin: "admin", owner: "owner" }

  # Scopes
  scope :active, -> { joins(:organization).where(organizations: { status: :active }) }
  scope :admins, -> { where(role: [ :admin, :owner ]) }
end
