class ApiConfiguration < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization

  # Note: acts_as_tenant automatically adds:
  # - belongs_to :organization
  # - default_scope to filter by current tenant
  # - validation to prevent cross-tenant associations

  # Encryption
  encrypts :encrypted_api_key

  # Validations
  validates :provider, presence: true
  validates :key_name, presence: true
  validates :encrypted_api_key, presence: true
  # Use validates_uniqueness_to_tenant for tenant-scoped uniqueness
  validates_uniqueness_to_tenant :key_name, scope: :provider

  # Enums
  enum :provider, {
    openai: "openai",
    anthropic: "anthropic",
    google: "google",
    azure_openai: "azure_openai"
  }

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Methods
  def masked_key
    return nil unless encrypted_api_key

    "****#{encrypted_api_key.last(4)}"
  end

  def validate_key!
    # TODO: Implement provider-specific validation
    update(last_validated_at: Time.current)
  end
end
