# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Monitoring::LlmResponses", type: :request do
  let(:organization) { create(:organization) }
  let(:api_key) { ActsAsTenant.with_tenant(organization) { create(:monitoring_api_key, organization: organization) } }
  let(:raw_token) { api_key.raw_token }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  let(:trace) do
    ActsAsTenant.with_tenant(organization) do
      PromptTracker::Trace.create!(
        name: "test-trace",
        status: "running",
        started_at: Time.current,
        external_id: "trace-ext-456"
      )
    end
  end

  describe "POST /api/v1/monitoring/llm_responses" do
    let(:valid_params) do
      {
        llm_response: {
          external_id: "resp-uuid-123",
          trace_id: trace.id,
          provider: "openai",
          model: "gpt-4o",
          rendered_prompt: "Classify this message",
          response_text: "intent: refund_request",
          status: "success",
          response_time_ms: 1850,
          tokens_prompt: 150,
          tokens_completion: 12,
          tokens_total: 162,
          cost_usd: 0.00243,
          environment: "production",
          user_id: "user-123",
          session_id: "session-abc"
        }
      }
    end

    context "without authentication" do
      it "returns 401" do
        post "/api/v1/monitoring/llm_responses", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid params" do
      it "creates an llm_response and returns 201" do
        post "/api/v1/monitoring/llm_responses", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body["id"]).to be_present
        expect(body["external_id"]).to eq("resp-uuid-123")
        expect(body["status"]).to eq("success")

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::LlmResponse.count).to eq(1)
        end
      end

      it "allows creating without agent_version_id (nullable)" do
        post "/api/v1/monitoring/llm_responses", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        llm_resp = ActsAsTenant.with_tenant(organization) { PromptTracker::LlmResponse.last }
        expect(llm_resp.agent_version_id).to be_nil
      end

      it "allows creating without rendered_prompt (nullable)" do
        params = valid_params.deep_dup
        params[:llm_response].delete(:rendered_prompt)

        post "/api/v1/monitoring/llm_responses", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
      end
    end

    context "with trace_external_id" do
      it "resolves trace by external_id" do
        # Force-create the trace before the request
        existing_trace = trace

        params = {
          llm_response: {
            trace_external_id: "trace-ext-456",
            provider: "openai",
            model: "gpt-4o",
            status: "success",
            response_text: "Hello"
          }
        }

        post "/api/v1/monitoring/llm_responses", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        llm_resp = ActsAsTenant.with_tenant(organization) { PromptTracker::LlmResponse.last }
        expect(llm_resp.trace_id).to eq(existing_trace.id)
      end
    end

    context "with invalid params" do
      it "returns 422 when provider is missing" do
        params = { llm_response: { model: "gpt-4o", status: "success" } }

        post "/api/v1/monitoring/llm_responses", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
      end
    end
  end
end
