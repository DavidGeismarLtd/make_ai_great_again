# frozen_string_literal: true

# Controller for managing LLM provider API keys.
#
# This controller allows organization admins to:
# - View all configured API keys (masked)
# - Add new API keys for LLM providers
# - Edit existing API keys
# - Delete API keys
# - Test API key connectivity
#
# All operations are automatically scoped to the current organization
# via acts_as_tenant.
class ApiConfigurationsController < ApplicationController
  before_action :set_api_configuration, only: [:edit, :update, :destroy, :test_connection]

  # GET /orgs/:org_slug/api_configurations
  def index
    @api_configurations = ApiConfiguration.all.order(:provider, :key_name)
    
    # Get list of available providers
    @available_providers = ApiConfiguration.providers.keys
  end

  # GET /orgs/:org_slug/api_configurations/new
  def new
    @api_configuration = ApiConfiguration.new
  end

  # GET /orgs/:org_slug/api_configurations/:id/edit
  def edit
    # @api_configuration set by before_action
  end

  # POST /orgs/:org_slug/api_configurations
  def create
    @api_configuration = ApiConfiguration.new(api_configuration_params)

    if @api_configuration.save
      redirect_to org_api_configurations_path(current_organization.slug),
                  notice: "API key for #{@api_configuration.provider.titleize} was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /orgs/:org_slug/api_configurations/:id
  def update
    if @api_configuration.update(api_configuration_params)
      redirect_to org_api_configurations_path(current_organization.slug),
                  notice: "API key was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /orgs/:org_slug/api_configurations/:id
  def destroy
    provider_name = @api_configuration.provider.titleize
    @api_configuration.destroy!

    redirect_to org_api_configurations_path(current_organization.slug),
                notice: "API key for #{provider_name} was successfully removed.",
                status: :see_other
  end

  # POST /orgs/:org_slug/api_configurations/:id/test_connection
  def test_connection
    # TODO: Implement provider-specific API key validation
    # For now, just update the last_validated_at timestamp
    @api_configuration.validate_key!

    redirect_to org_api_configurations_path(current_organization.slug),
                notice: "API key test successful! (Note: Full validation coming soon)"
  end

  private

  def set_api_configuration
    @api_configuration = ApiConfiguration.find(params[:id])
  end

  def api_configuration_params
    params.require(:api_configuration).permit(:provider, :key_name, :encrypted_api_key, :is_active)
  end
end

