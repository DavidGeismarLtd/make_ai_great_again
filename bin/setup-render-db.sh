#!/usr/bin/env bash
# Script to setup database in Render environment
# Run this manually in Render Shell if migrations fail during build

set -o errexit

echo "Setting up database for Render..."

# Run migrations for primary database
echo "Running primary database migrations..."
bundle exec rails db:migrate RAILS_ENV=production

# Run migrations for cache database
echo "Running cache database migrations..."
bundle exec rails db:migrate:cache RAILS_ENV=production || echo "Cache migrations skipped (may not be needed)"

# Run migrations for cable database
echo "Running cable database migrations..."
bundle exec rails db:migrate:cable RAILS_ENV=production || echo "Cable migrations skipped (may not be needed)"

echo "Database setup complete!"

