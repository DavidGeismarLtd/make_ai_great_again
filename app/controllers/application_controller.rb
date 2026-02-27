class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Pundit authorization
  include Pundit::Authorization

  # LLM API key management
  include SetsLlmApiKeys

  # Multi-tenancy
  set_current_tenant_through_filter
  before_action :authenticate_user!
  before_action :set_current_tenant

  # Error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :no_tenant_set

  private

  def set_current_tenant
    return unless user_signed_in?

    # Find organization from params or user's default
    # We need to bypass tenant requirement when fetching user's organizations
    # because OrganizationMembership has acts_as_tenant :organization
    organization = ActsAsTenant.without_tenant do
      if params[:organization_id]
        current_user.organizations.find(params[:organization_id])
      elsif params[:org_slug]
        current_user.organizations.find_by!(slug: params[:org_slug])
      else
        current_user.organizations.first
      end
    end

    ActsAsTenant.current_tenant = organization
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def no_tenant_set
    flash[:alert] = "Please select an organization."
    redirect_to root_path
  end

  helper_method :current_organization

  def current_organization
    ActsAsTenant.current_tenant
  end
end
