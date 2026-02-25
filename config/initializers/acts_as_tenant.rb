# frozen_string_literal: true

ActsAsTenant.configure do |config|
  # Raise error if tenant not set (fail-safe)
  config.require_tenant = true

  # Customize the query for loading the tenant in background jobs
  # Only load active organizations
  config.job_scope = ->{ where(status: :active) }
end

# Enable Sidekiq integration for background jobs
require "acts_as_tenant/sidekiq"

