# frozen_string_literal: true

# Custom Devise RegistrationsController to handle user signup with organization creation.
#
# This controller overrides Devise's default registration flow to:
# 1. Skip tenant requirement (new users don't have an organization yet)
# 2. Permit additional parameters (first_name, last_name)
# 3. Use UserRegistrationService to atomically create user + organization
# 4. Redirect to the testing dashboard after successful signup
#
# The standard Devise flow only creates a user account. Our flow creates:
# - User account
# - Organization (auto-named based on user's first name)
# - Organization membership (user as owner)
# - Organization configuration (with default settings)
class Users::RegistrationsController < Devise::RegistrationsController
  # Skip tenant requirement for registration actions
  # New users don't have an organization yet, so we can't set a tenant
  skip_before_action :set_current_tenant, only: [ :new, :create ]
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    build_resource(sign_up_params)

    # Use UserRegistrationService to create user + organization atomically
    result = UserRegistrationService.call(resource)

    if result.success?
      # Sign in the user
      sign_up(resource_name, resource)

      # Set flash message
      set_flash_message! :notice, :signed_up

      # Redirect to testing dashboard
      redirect_to after_sign_up_path_for(resource)
    else
      # Registration failed - show errors
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # GET /users/edit
  def edit
    super
  end

  # PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  protected

  # Configure permitted parameters for sign up
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end

  # Configure permitted parameters for account update
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  # Override Devise's after_sign_up_path to redirect to testing dashboard
  def after_sign_up_path_for(resource)
    # Get the user's organization (just created by UserRegistrationService)
    organization = ActsAsTenant.without_tenant do
      resource.organizations.first
    end

    if organization
      # Redirect to testing dashboard: /orgs/:org_slug/app/testing
      org_prompt_tracker.testing_root_path(org_slug: organization.slug)
    else
      # Fallback to root path if something went wrong
      root_path
    end
  end

  # Override Devise's after_update_path to stay on edit page
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end
