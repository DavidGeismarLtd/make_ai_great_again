# frozen_string_literal: true

# Configure Resend API key for email delivery in production only
# Development uses letter_opener, test uses :test delivery method
if Rails.env.production? && ENV["RESEND_API_KEY"].present?
  Resend.api_key = ENV["RESEND_API_KEY"]
end
