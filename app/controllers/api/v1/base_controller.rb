# frozen_string_literal: true

# Base controller for all API v1 endpoints.
#
# Provides:
# - Bearer token authentication via MonitoringApiKey
# - Tenant resolution (sets ActsAsTenant.current_tenant)
# - Consistent JSON error responses
# - No cookies, no CSRF, no session (ActionController::API)
module Api
  module V1
    class BaseController < ActionController::API
      include ActsAsTenant::ControllerExtensions

      set_current_tenant_through_filter
      before_action :authenticate_with_api_key!

      private

      # Authenticate the request using Bearer token from Authorization header.
      # Sets the current tenant to the organization associated with the API key.
      def authenticate_with_api_key!
        token = extract_bearer_token
        if token.blank?
          render_error("unauthorized", "Missing or invalid Authorization header. Use: Authorization: Bearer <token>", status: :unauthorized)
          return
        end

        @current_api_key = MonitoringApiKey.find_by_token(token)

        if @current_api_key.nil?
          render_error("unauthorized", "Invalid API key", status: :unauthorized)
          return
        end

        if @current_api_key.revoked?
          render_error("forbidden", "API key has been revoked", status: :forbidden)
          return
        end

        # Set the tenant for acts_as_tenant scoping
        ActsAsTenant.current_tenant = @current_api_key.organization

        # Record usage (non-blocking, skip validations)
        @current_api_key.touch_last_used!
      end

      # Extract bearer token from Authorization header.
      # @return [String, nil]
      def extract_bearer_token
        header = request.headers["Authorization"]
        return nil if header.blank?

        scheme, token = header.split(" ", 2)
        return nil unless scheme&.casecmp("bearer")&.zero?

        token
      end

      # Accessor for the authenticated API key
      attr_reader :current_api_key

      # Render a consistent JSON error response.
      # @param code [String] machine-readable error code
      # @param message [String] human-readable message
      # @param status [Symbol] HTTP status
      # @param details [Hash, nil] optional validation error details
      def render_error(code, message, status:, details: nil)
        body = {
          error: {
            code: code,
            message: message
          }
        }
        body[:error][:details] = details if details.present?

        render json: body, status: status
      end

      # Render validation errors from an ActiveRecord model.
      # @param record [ActiveRecord::Base]
      def render_validation_errors(record)
        render_error(
          "validation_failed",
          "Validation failed: #{record.errors.full_messages.join(', ')}",
          status: :unprocessable_entity,
          details: record.errors.messages
        )
      end
    end
  end
end
