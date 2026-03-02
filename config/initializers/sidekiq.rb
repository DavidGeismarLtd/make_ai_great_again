# frozen_string_literal: true

# Sidekiq configuration
# See https://github.com/sidekiq/sidekiq/wiki/Advanced-Options

# Redis connection configuration
redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  network_timeout: 5,
  pool_timeout: 5
}

# Configure Sidekiq server (worker process)
Sidekiq.configure_server do |config|
  config.redis = redis_config

  # Enable strict argument checking
  config.strict_args!

  # Configure ActiveRecord connection pool
  # Sidekiq uses 10 connections by default (concurrency + 2)
  # Adjust based on your concurrency setting in sidekiq.yml
  config.on(:startup) do
    Rails.application.config.after_initialize do
      ActiveRecord::Base.connection_pool.disconnect!

      # Set pool size to match Sidekiq concurrency + 2
      # This ensures enough connections for all Sidekiq threads
      ActiveRecord::Base.establish_connection(
        ActiveRecord::Base.connection_db_config.configuration_hash.merge(
          pool: Sidekiq.options[:concurrency] + 2
        )
      )
    end
  end
end

# Configure Sidekiq client (Rails app)
Sidekiq.configure_client do |config|
  config.redis = redis_config
end

# Optional: Configure Sidekiq logger
Sidekiq.logger.level = Logger::INFO if Rails.env.production?

# Optional: Configure error handling
# Sidekiq.configure_server do |config|
#   config.error_handlers << proc { |ex, ctx_hash|
#     # Send to error tracking service (Sentry, Rollbar, etc.)
#     Rails.logger.error("Sidekiq error: #{ex.message}")
#   }
# end

