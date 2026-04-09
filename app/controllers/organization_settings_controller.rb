# frozen_string_literal: true

# Controller for managing organization-specific PromptTracker settings
# Handles contexts (playground, llm_judge, etc.) and features (feature flags)
class OrganizationSettingsController < ApplicationController
  before_action :set_organization_configuration

  def show
    # Overview page showing all settings
  end

  def edit
    # Main settings edit page
  end

  def update
    if @organization_configuration.update(organization_configuration_params)
      redirect_to org_organization_settings_path(current_organization.slug),
                  notice: "Organization settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Contexts management
  def contexts
    # Page for editing context defaults (playground, llm_judge, etc.)
    # Get list of configured providers (only show providers with API keys)
    @configured_providers = ApiConfiguration.active.pluck(:provider).uniq
  end

  def update_contexts
    if @organization_configuration.update(contexts_config: contexts_params)
      redirect_to contexts_org_organization_settings_path(current_organization.slug),
                  notice: "Context settings updated successfully."
    else
      render :contexts, status: :unprocessable_entity
    end
  end

  # Features management
  def features
    # Page for editing feature flags
  end

  def update_features
    # Convert string "true"/"false" to boolean values
    features = features_params.transform_values { |v| v == "true" }

    if @organization_configuration.update(features_config: features)
      redirect_to features_org_organization_settings_path(current_organization.slug),
                  notice: "Feature settings updated successfully."
    else
      render :features, status: :unprocessable_entity
    end
  end

  # Function providers management
  def function_providers
    # Page for editing function provider settings (AWS Lambda, etc.)
  end

  def update_function_providers
    if @organization_configuration.update(function_providers_config: function_providers_params)
      redirect_to function_providers_org_organization_settings_path(current_organization.slug),
                  notice: "Function provider settings updated successfully."
    else
      render :function_providers, status: :unprocessable_entity
    end
  end

  # Assistant chatbot management
  def assistant_chatbot
    # Page for editing assistant chatbot settings
    @configured_providers = ApiConfiguration.active.pluck(:provider).uniq
  end

  def update_assistant_chatbot
    chatbot_config = assistant_chatbot_params
    # Convert "true"/"false" string to boolean for JSONB storage
    chatbot_config["enabled"] = chatbot_config["enabled"] == "true"

    if @organization_configuration.update(assistant_chatbot_config: chatbot_config)
      redirect_to assistant_chatbot_org_organization_settings_path(current_organization.slug),
                  notice: "Assistant chatbot settings updated successfully."
    else
      render :assistant_chatbot, status: :unprocessable_entity
    end
  end

  private

  def set_organization_configuration
    # Find or create organization configuration
    @organization_configuration = current_organization.organization_configuration

    unless @organization_configuration
      @organization_configuration = current_organization.build_organization_configuration
      @organization_configuration.save!
    end
  end

  def organization_configuration_params
    params.require(:organization_configuration).permit(
      contexts_config: {},
      features_config: {}
    )
  end

  def contexts_params
    params.require(:contexts_config).permit!.to_h
  end

  def features_params
    params.require(:features_config).permit!.to_h
  end

  def function_providers_params
    params.require(:function_providers_config).permit!.to_h
  end

  def assistant_chatbot_params
    params.require(:assistant_chatbot_config).permit!.to_h
  end
end
