# Preview all emails at http://localhost:3000/rails/mailers/organization_invitation_mailer
class OrganizationInvitationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/organization_invitation_mailer/invite
  def invite
    # Create a sample invitation for preview
    organization = Organization.first || Organization.create!(
      name: "Sample Organization",
      slug: "sample-org",
      status: "active"
    )

    user = User.first || User.create!(
      email: "admin@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "User",
      role: "admin",
      confirmed_at: Time.current
    )

    invitation = OrganizationInvitation.new(
      organization: organization,
      email: "newuser@example.com",
      role: "member",
      invited_by: user,
      token: SecureRandom.urlsafe_base64(32),
      expires_at: 7.days.from_now
    )

    OrganizationInvitationMailer.invite(invitation)
  end

end
