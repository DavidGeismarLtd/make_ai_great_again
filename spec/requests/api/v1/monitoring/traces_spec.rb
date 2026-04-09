# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Monitoring::Traces", type: :request do
  let(:organization) { create(:organization) }
  let(:api_key) { ActsAsTenant.with_tenant(organization) { create(:monitoring_api_key, organization: organization) } }
  let(:raw_token) { api_key.raw_token }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  describe "POST /api/v1/monitoring/traces" do
    let(:valid_params) do
      {
        trace: {
          external_id: "trace-uuid-123",
          name: "customer-support-pipeline",
          input: "User asked about refund",
          status: "running",
          session_id: "session-abc",
          user_id: "user-123",
          started_at: "2026-04-09T10:00:00Z",
          metadata: { environment: "production" }
        }
      }
    end

    context "without authentication" do
      it "returns 401" do
        post "/api/v1/monitoring/traces", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]["code"]).to eq("unauthorized")
      end
    end

    context "with revoked API key" do
      it "returns 403" do
        api_key.revoke!

        post "/api/v1/monitoring/traces", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]["code"]).to eq("forbidden")
      end
    end

    context "with valid params" do
      it "creates a trace and returns 201" do
        post "/api/v1/monitoring/traces", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body["id"]).to be_present
        expect(body["external_id"]).to eq("trace-uuid-123")
        expect(body["status"]).to eq("running")

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::Trace.count).to eq(1)
        end
      end

      it "associates trace with the correct organization" do
        post "/api/v1/monitoring/traces", params: valid_params, headers: auth_headers, as: :json

        trace = ActsAsTenant.with_tenant(organization) { PromptTracker::Trace.last }
        expect(trace.organization_id).to eq(organization.id)
        expect(trace.name).to eq("customer-support-pipeline")
      end
    end

    context "with invalid params" do
      it "returns 422 when name is missing" do
        invalid_params = { trace: { status: "running", started_at: Time.current } }

        post "/api/v1/monitoring/traces", params: invalid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
      end
    end

    context "with tenant isolation" do
      it "does not allow access to other organization's data" do
        other_org = create(:organization)

        post "/api/v1/monitoring/traces", params: valid_params, headers: auth_headers, as: :json

        # The trace should belong to the API key's org, not the other org
        ActsAsTenant.with_tenant(other_org) do
          expect(PromptTracker::Trace.count).to eq(0)
        end
      end
    end
  end
end
