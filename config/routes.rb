Rails.application.routes.draw do
  # Devise routes with custom controllers
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Static pages
  get "privacy", to: "pages#privacy", as: :privacy
  get "terms", to: "pages#terms", as: :terms
  get "guides", to: "pages#guides", as: :guides

  # Contact form
  post "contact", to: "contacts#create", as: :contact

  # Invitation acceptance (public, no org scope)
  get "invitations/:token", to: "invitation_acceptances#show", as: :invitation
  post "invitations/:token/accept", to: "invitation_acceptances#accept", as: :accept_invitation
  post "invitations/:token/create_account", to: "invitation_acceptances#create_account", as: :create_account_invitation

  # Organization-scoped routes
  # All PromptTracker routes are scoped under /orgs/:org_slug/app
  # This ensures complete data isolation and clear URL structure
  scope "/orgs/:org_slug", as: :org do
    # API Key Management
    resources :api_configurations do
      member do
        post :test_connection
      end
    end

    # Organization Settings (contexts, features, etc.)
    resource :organization_settings, only: [ :show, :edit, :update ], path: "settings" do
      member do
        get :contexts
        patch :update_contexts
        get :features
        patch :update_features
      end
    end

    # Organization Invitations
    resources :organization_invitations, only: [ :index, :new, :create, :destroy ], path: "invitations" do
      member do
        post :resend
      end
    end

    # Mount PromptTracker engine at /orgs/:org_slug/app
    # The :org_slug param is automatically available in ApplicationController#set_current_tenant
    mount PromptTracker::Engine, at: "/app", as: :prompt_tracker

    # Future: Add other organization-scoped routes here
    # resources :team_members
    # etc.
  end
end
