# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PromptTracker Engine Routing", type: :routing do
  describe "organization-scoped routes" do
    it "routes to PromptTracker engine under /orgs/:org_slug/app" do
      expect(get: "/orgs/acme-corp/app").to route_to(
        controller: "prompt_tracker/home",
        action: "index",
        org_slug: "acme-corp"
      )
    end

    it "generates correct path for organization-scoped PromptTracker" do
      expect(org_prompt_tracker_path(org_slug: "acme-corp")).to eq("/orgs/acme-corp/app")
    end

    it "includes org_slug in params for all PromptTracker routes" do
      # Test a nested route within the engine
      expect(get: "/orgs/test-org/app/testing").to route_to(
        controller: "prompt_tracker/testing/dashboard",
        action: "index",
        org_slug: "test-org"
      )
    end
  end

  describe "URL helpers" do
    it "provides org_prompt_tracker_path helper" do
      expect(org_prompt_tracker_path(org_slug: "my-org")).to eq("/orgs/my-org/app")
    end

    it "provides org_prompt_tracker_url helper" do
      expect(org_prompt_tracker_url(org_slug: "my-org", host: "example.com")).to eq("http://example.com/orgs/my-org/app")
    end
  end
end

