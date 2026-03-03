# frozen_string_literal: true

# Override PromptTracker's ApplicationController to inherit from host app's ApplicationController
# This ensures authentication and tenant scoping work correctly for all PromptTracker controllers
#
# By inheriting from ::ApplicationController, all PromptTracker controllers will:
# - Require authentication via Devise (before_action :authenticate_user!)
# - Set the current tenant based on params[:org_slug] (before_action :set_current_tenant)
# - Have access to Pundit authorization
# - Have access to current_user, current_organization, and other host app helpers
#
# This is a common pattern when mounting Rails engines to ensure they respect
# the host application's authentication and authorization setup.
module PromptTracker
  class ApplicationController < ::ApplicationController
    # All PromptTracker controllers now inherit from the host app's ApplicationController
    # No additional configuration needed - they automatically get all the host app's
    # before_actions, helper methods, and concerns

    # Override default_url_options to include org_slug in all URL generation
    # This is necessary because the engine is mounted under /orgs/:org_slug/app
    # and the engine's views don't know about the org_slug requirement
    def default_url_options
      if current_organization.present?
        super.merge(org_slug: current_organization.slug)
      else
        super
      end
    end
  end
end
