# frozen_string_literal: true

# POST /api/v1/monitoring/traces
#
# Creates a single trace for distributed tracing of LLM pipelines.
# Supports idempotent writes via external_id.
module Api
  module V1
    module Monitoring
      class TracesController < Api::V1::BaseController
        # POST /api/v1/monitoring/traces
        def create
          trace = PromptTracker::Trace.new(trace_params)
          trace.organization = ActsAsTenant.current_tenant

          if trace.save
            render json: {
              id: trace.id,
              external_id: trace.external_id,
              status: trace.status,
              created_at: trace.created_at
            }, status: :created
          else
            render_validation_errors(trace)
          end
        end

        private

        def trace_params
          params.require(:trace).permit(
            :external_id,
            :name,
            :input,
            :output,
            :status,
            :session_id,
            :user_id,
            :started_at,
            :ended_at,
            :duration_ms,
            metadata: {}
          )
        end
      end
    end
  end
end
