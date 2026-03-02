#!/usr/bin/env bash
# exit on error
set -o errexit

echo "==> Installing dependencies..."
bundle install

echo "==> Precompiling assets..."
bundle exec rake assets:precompile

echo "==> Setting up database..."
# Use db:schema:load for first-time setup, then db:migrate for updates
# DISABLE_DATABASE_ENVIRONMENT_CHECK allows us to modify production DB
if bundle exec rake db:version 2>/dev/null; then
  echo "Database exists, running migrations..."
  bundle exec rake db:migrate
else
  echo "Database is new, loading schema..."
  DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:schema:load
fi

echo "==> Build complete!"
