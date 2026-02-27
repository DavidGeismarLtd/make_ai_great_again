class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_before_action :set_current_tenant, only: [ :index ]

  def index
    # Redirect authenticated users to their organization dashboard
    if user_signed_in? && current_user.organizations.any?
      # Get the user's first organization (or last visited - can be enhanced later)
      org = current_user.organizations.first
      redirect_to org_prompt_tracker.root_path(org_slug: org.slug)
    end
    # Otherwise, show the landing page
  end
end
