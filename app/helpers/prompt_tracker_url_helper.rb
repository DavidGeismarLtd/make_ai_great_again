# frozen_string_literal: true

# Helper module to provide organization-scoped URL generation for PromptTracker
#
# This module overrides PromptTracker's default_url_options to include the org_slug
# parameter in all generated URLs. This is necessary because the host application
# mounts PromptTracker under /orgs/:org_slug/app, but the engine's views don't
# know about the org_slug requirement.
#
# How it works:
# 1. PromptTracker controllers inherit from ::ApplicationController
# 2. This helper is included in ApplicationHelper
# 3. When PromptTracker views call url_for or path helpers, they get org_slug automatically
#
# Example:
#   # In PromptTracker view:
#   testing_prompt_version_tests_path(version)
#   # Becomes:
#   /orgs/acme-corp/app/testing/prompts/1/versions/1/tests
module PromptTrackerUrlHelper
  # Override default_url_options to include org_slug for all PromptTracker routes
  def default_url_options
    options = super || {}
    
    # Add org_slug if we're in a PromptTracker controller and have a current organization
    if controller.class.name.start_with?("PromptTracker::") && current_organization.present?
      options.merge(org_slug: current_organization.slug)
    else
      options
    end
  end
end

