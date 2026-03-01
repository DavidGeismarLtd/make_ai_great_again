class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_before_action :set_current_tenant, only: [ :index ]

  def index
    # Redirect authenticated users to their organization dashboard
    # Use without_tenant because OrganizationMembership has acts_as_tenant
    if user_signed_in?
      org = ActsAsTenant.without_tenant do
        current_user.organizations.first
      end

      if org
        redirect_to org_prompt_tracker.root_path(org_slug: org.slug)
      end
    end
    # Otherwise, show the landing page
  end
end
