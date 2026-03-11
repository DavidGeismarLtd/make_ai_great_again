# frozen_string_literal: true

# Controller for managing organization invitations
# Allows admins/owners to invite users to their organization
class OrganizationInvitationsController < ApplicationController
  before_action :set_invitation, only: [:destroy, :resend]
  before_action :authorize_invitation_management, only: [:index, :new, :create, :destroy, :resend]

  # GET /orgs/:org_slug/invitations
  def index
    @pending_invitations = current_organization.organization_invitations.pending.order(created_at: :desc)
    @accepted_invitations = current_organization.organization_invitations.accepted.order(accepted_at: :desc).limit(10)
    @expired_invitations = current_organization.organization_invitations.expired.order(created_at: :desc).limit(10)
  end

  # GET /orgs/:org_slug/invitations/new
  def new
    @invitation = current_organization.organization_invitations.build
  end

  # POST /orgs/:org_slug/invitations
  def create
    @invitation = current_organization.organization_invitations.build(invitation_params)
    @invitation.invited_by = current_user

    if @invitation.save
      # Send invitation email
      send_invitation_email(@invitation)
      redirect_to org_organization_invitations_path(current_organization.slug),
                  notice: "Invitation sent to #{@invitation.email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /orgs/:org_slug/invitations/:id
  def destroy
    @invitation.destroy
    redirect_to org_organization_invitations_path(current_organization.slug),
                notice: "Invitation cancelled"
  end

  # POST /orgs/:org_slug/invitations/:id/resend
  def resend
    if @invitation.pending?
      # Update expiration and resend
      @invitation.update(expires_at: 7.days.from_now)
      send_invitation_email(@invitation)
      redirect_to org_organization_invitations_path(current_organization.slug),
                  notice: "Invitation resent to #{@invitation.email}"
    else
      redirect_to org_organization_invitations_path(current_organization.slug),
                  alert: "Cannot resend this invitation"
    end
  end

  private

  def set_invitation
    @invitation = current_organization.organization_invitations.find(params[:id])
  end

  def invitation_params
    params.require(:organization_invitation).permit(:email, :role)
  end

  def authorize_invitation_management
    # Only admins and owners can manage invitations
    membership = current_user.organization_memberships.find_by(organization: current_organization)
    unless membership&.admin? || membership&.owner?
      flash[:alert] = "You are not authorized to manage invitations"
      redirect_to org_prompt_tracker.root_path(org_slug: current_organization.slug)
    end
  end

  def send_invitation_email(invitation)
    # In development, use deliver_now so letter_opener can show the email immediately
    # In production, use deliver_later for background processing
    if Rails.env.development?
      OrganizationInvitationMailer.invite(invitation).deliver_now
    else
      OrganizationInvitationMailer.invite(invitation).deliver_later
    end
  end
end
