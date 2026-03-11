# frozen_string_literal: true

# Configure Resend API key for email delivery in production only
# Development uses letter_opener, test uses :test delivery method
if Rails.env.production?
  Resend.api_key = ENV.fetch("RESEND_API_KEY")
end
