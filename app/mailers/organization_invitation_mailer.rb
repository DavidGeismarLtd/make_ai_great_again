class OrganizationInvitationMailer < ApplicationMailer
  # Send invitation email to join an organization
  def invite(invitation)
    @invitation = invitation
    @organization = invitation.organization
    @invited_by = invitation.invited_by
    @accept_url = invitation_url(invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@organization.name} on AgentsOnRails"
    )
  end
end
