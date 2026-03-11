class OrganizationInvitation < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: %w[viewer member admin] }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :email_not_already_member
  validate :no_pending_invitation, on: :create

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  before_validation :normalize_email

  # Scopes
  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  # Methods
  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  def expired?
    accepted_at.nil? && expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    return false if expired? || accepted?

    # Set tenant context for the entire operation
    ActsAsTenant.with_tenant(organization) do
      transaction do
        update!(accepted_at: Time.current)
        OrganizationMembership.create!(
          organization: organization,
          user: user,
          role: role
        )
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def email_not_already_member
    return unless organization && email.present?

    if organization.users.exists?(email: email)
      errors.add(:email, "is already a member of this organization")
    end
  end

  def no_pending_invitation
    return unless organization && email.present?

    if organization.organization_invitations.pending.exists?(email: email)
      errors.add(:email, "already has a pending invitation")
    end
  end
end
