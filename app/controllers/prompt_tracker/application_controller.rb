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
    # Re-declare helpers from the gem since we're overriding the base controller
    helper PromptTracker::DatasetsHelper
    helper PromptTracker::TestsHelper
    helper PromptTracker::UrlHelper
    # All PromptTracker controllers now inherit from the host app's ApplicationController
    # No additional configuration needed - they automatically get all the host app's
    # before_actions, helper methods, and concerns
    #
    # Note: URL generation for multi-tenant routes is handled by the PromptTracker gem's
    # url_options_provider configuration (see config/initializers/prompt_tracker.rb)
  end
end
