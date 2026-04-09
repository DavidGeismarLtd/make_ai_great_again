# frozen_string_literal: true

# Helper methods for navigation components
module NavigationHelper
  # Generate user initials from first and last name
  # @param user [User] the user object
  # @return [String] two-letter initials (e.g., "DG" for David Geismar)
  def user_initials(user)
    return "?" unless user&.first_name && user&.last_name

    "#{user.first_name[0]}#{user.last_name[0]}".upcase
  end

  # Generate consistent avatar background color based on user ID
  # @param user [User] the user object
  # @return [String] hex color code
  def user_avatar_color(user)
    colors = [
      "#007BFF", # electric blue
      "#00D97E", # neon green
      "#FFC107", # yellow
      "#DC3545", # red
      "#17A2B8"  # cyan
    ]
    colors[user.id % colors.length]
  end

  # Convert flash type to Bootstrap alert class
  # @param flash_type [String, Symbol] the flash message type
  # @return [String] Bootstrap alert class
  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :success then "success"
    when :error then "danger"
    when :alert then "warning"
    when :notice then "info"
    else flash_type.to_s
    end
  end

  # Determine current section based on controller path
  # @return [String] current section name
  def current_section
    if controller_path.start_with?("prompt_tracker/testing")
      "testing"
    elsif controller_path.start_with?("prompt_tracker/monitoring")
      "monitoring"
    elsif controller_path.start_with?("prompt_tracker/functions")
      "functions"
    elsif controller_path.start_with?("organizations")
      "organizations"
    elsif controller_path.start_with?("api_configurations")
      "api_keys"
    else
      "home"
    end
  end

  # Check if current page is within PromptTracker engine
  # @return [Boolean]
  def in_prompt_tracker?
    controller_path.start_with?("prompt_tracker/")
  end

  # Get user's organizations (bypassing tenant requirement)
  # @return [ActiveRecord::Relation]
  def user_organizations
    return [] unless user_signed_in?

    ActsAsTenant.without_tenant do
      current_user.organizations.order(:name)
    end
  end

  # Check if user has multiple organizations
  # @return [Boolean]
  def multiple_organizations?
    user_organizations.count > 1
  end
end
