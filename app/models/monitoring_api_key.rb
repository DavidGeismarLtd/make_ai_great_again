# frozen_string_literal: true

# MonitoringApiKey provides bearer token authentication for the Monitoring API.
#
# External SDKs use these keys to send traces, spans, and LLM responses
# via POST /api/v1/monitoring/* endpoints.
#
# Security:
# - Raw tokens are shown only once at creation time
# - Only the SHA-256 digest is stored in the database
# - token_prefix stores first 8 chars for identification in UI
#
# Usage:
#   key = MonitoringApiKey.create!(name: "Production", created_by: "alice@example.com")
#   key.raw_token  # => "pt_mon_abc123..." (only available right after create)
#
#   # Later, for authentication:
#   MonitoringApiKey.find_by_token("pt_mon_abc123...")  # => MonitoringApiKey or nil
class MonitoringApiKey < ApplicationRecord
  TOKEN_PREFIX = "pt_mon_"

  acts_as_tenant :organization

  # Associations
  belongs_to :organization

  # Validations
  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true
  validates :status, presence: true, inclusion: { in: %w[active revoked] }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :revoked, -> { where(status: "revoked") }

  # Callbacks
  before_validation :generate_token, on: :create

  # Transient attribute — only available immediately after creation
  attr_reader :raw_token

  # Find a key by raw token. Returns nil if not found.
  # Searches without tenant scope since the token is used to *determine* the tenant.
  # @param raw_token [String] the full raw token (e.g. "pt_mon_abc123...")
  # @return [MonitoringApiKey, nil]
  def self.find_by_token(raw_token)
    return nil if raw_token.blank?

    digest = compute_digest(raw_token)
    ActsAsTenant.without_tenant { find_by(token_digest: digest) }
  end

  # Find an active key by raw token.
  # Searches without tenant scope since the token is used to *determine* the tenant.
  # @param raw_token [String]
  # @return [MonitoringApiKey, nil]
  def self.find_active_by_token(raw_token)
    return nil if raw_token.blank?

    digest = compute_digest(raw_token)
    ActsAsTenant.without_tenant { active.find_by(token_digest: digest) }
  end

  # Revoke this API key.
  def revoke!
    update!(status: "revoked", revoked_at: Time.current)
  end

  # Is this key currently active?
  def active?
    status == "active"
  end

  # Is this key revoked?
  def revoked?
    status == "revoked"
  end

  # Record usage timestamp (called from BaseController on each request)
  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  private

  def generate_token
    raw = "#{TOKEN_PREFIX}#{SecureRandom.hex(32)}"
    @raw_token = raw
    self.token_digest = self.class.compute_digest(raw)
    self.token_prefix = raw[0, 12]
  end

  def self.compute_digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end
end
