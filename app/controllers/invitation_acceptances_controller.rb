# frozen_string_literal: true

# Controller for accepting organization invitations
# Public controller - no authentication required
class InvitationAcceptancesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :accept, :create_account]
  skip_before_action :set_current_tenant, only: [:show, :accept, :create_account]

  # GET /invitations/:token
  def show
    @invitation = OrganizationInvitation.find_by!(token: params[:token])
    @organization = @invitation.organization
    @invited_by = @invitation.invited_by

    if @invitation.expired?
      render :expired
    elsif @invitation.accepted?
      render :already_accepted
    elsif user_signed_in?
      # User is already signed in, verify email matches
      if current_user.email.downcase == @invitation.email.downcase
        # Show acceptance confirmation page
        @user = current_user
        render :show
      else
        # Email mismatch - user needs to sign in with the invited email
        sign_out current_user
        store_location_for(:user, invitation_path(@invitation.token))
        redirect_to new_user_session_path,
                    alert: "This invitation was sent to #{@invitation.email}. Please sign in with that email."
      end
    else
      # User not signed in - check if account exists
      @user = User.find_by(email: @invitation.email)
      if @user
        # Account exists - redirect to sign in
        store_location_for(:user, invitation_path(@invitation.token))
        redirect_to new_user_session_path,
                    notice: "Please sign in with #{@invitation.email} to accept the invitation"
      else
        # No account - show registration form with email pre-filled
        @user = User.new(email: @invitation.email)
        @minimum_password_length = User.password_length.min
        render :new_user
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end

  # POST /invitations/:token/accept
  # For existing users who are already signed in
  def accept
    @invitation = OrganizationInvitation.find_by!(token: params[:token])

    unless user_signed_in?
      redirect_to invitation_path(@invitation.token), alert: "Please sign in first"
      return
    end

    if @invitation.expired?
      redirect_to invitation_path(@invitation.token), alert: "This invitation has expired"
      return
    end

    if @invitation.accepted?
      redirect_to invitation_path(@invitation.token), alert: "This invitation has already been accepted"
      return
    end

    # Verify email matches (case-insensitive)
    unless current_user.email.downcase == @invitation.email.downcase
      redirect_to invitation_path(@invitation.token),
                  alert: "This invitation was sent to #{@invitation.email}, but you are signed in as #{current_user.email}"
      return
    end

    if @invitation.accept!(current_user)
      redirect_to org_prompt_tracker.root_path(org_slug: @invitation.organization.slug),
                  notice: "Welcome to #{@invitation.organization.name}!"
    else
      redirect_to invitation_path(@invitation.token),
                  alert: "Unable to accept invitation. You may already be a member of this organization."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invitation not found"
  end

  # POST /invitations/:token/create_account
  # For new users who need to create an account
  def create_account
    @invitation = OrganizationInvitation.find_by!(token: params[:token])
    @organization = @invitation.organization
    @invited_by = @invitation.invited_by

    if @invitation.expired?
      redirect_to invitation_path(@invitation.token), alert: "This invitation has expired"
      return
    end

    if @invitation.accepted?
      redirect_to invitation_path(@invitation.token), alert: "This invitation has already been accepted"
      return
    end

    # Create user with invitation email and auto-confirm since invitation validates email
    @user = User.new(user_params.merge(
      email: @invitation.email,
      confirmed_at: Time.current  # Auto-confirm email since they were invited
    ))

    if @user.save
      # Sign in the new user
      sign_in(@user)

      # Accept the invitation
      if @invitation.accept!(@user)
        redirect_to org_prompt_tracker.root_path(org_slug: @invitation.organization.slug),
                    notice: "Account created! Welcome to #{@invitation.organization.name}!"
      else
        redirect_to invitation_path(@invitation.token),
                    alert: "Account created but unable to accept invitation."
      end
    else
      @minimum_password_length = User.password_length.min
      render :new_user, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invitation not found"
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end
end
