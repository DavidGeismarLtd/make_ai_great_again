Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Organization-scoped routes
  # All PromptTracker routes are scoped under /orgs/:org_slug/app
  # This ensures complete data isolation and clear URL structure
  scope "/orgs/:org_slug" do
    # Mount PromptTracker engine at /orgs/:org_slug/app
    # The :org_slug param is automatically available in ApplicationController#set_current_tenant
    mount PromptTracker::Engine, at: "/app", as: :org_prompt_tracker

    # Future: Add other organization-scoped routes here
    # resources :api_configurations
    # resources :team_members
    # etc.
  end
end
