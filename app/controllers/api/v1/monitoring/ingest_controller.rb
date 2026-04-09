# frozen_string_literal: true

# POST /api/v1/monitoring/ingest
#
# Batch endpoint that accepts a complete trace tree (trace + spans + llm_responses)
# in a single request. This is the recommended endpoint for SDKs.
#
# All records are created in a single database transaction (all-or-nothing).
# Supports idempotent writes via external_id fields.
module Api
  module V1
    module Monitoring
      class IngestController < Api::V1::BaseController
        # POST /api/v1/monitoring/ingest
        def create
          result = ::Monitoring::IngestService.call(
            trace_params: ingest_trace_params,
            spans_params: ingest_spans_params
          )

          if result.success?
            render json: build_response(result), status: :created
          else
            render_error("validation_failed", result.error, status: :unprocessable_entity)
          end
        end

        private

        def ingest_trace_params
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

        def ingest_spans_params
          return [] unless params[:spans].present?

          params[:spans].map do |span|
            span.permit(
              :external_id,
              :parent_span_external_id,
              :name,
              :span_type,
              :input,
              :output,
              :status,
              :started_at,
              :ended_at,
              :duration_ms,
              metadata: {},
              llm_response: [
                :external_id,
                :provider,
                :model,
                :rendered_prompt,
                :rendered_system_prompt,
                :response_text,
                :status,
                :error_type,
                :error_message,
                :response_time_ms,
                :tokens_prompt,
                :tokens_completion,
                :tokens_total,
                :cost_usd,
                :environment,
                :user_id,
                :session_id,
                :conversation_id,
                :turn_number,
                { variables_used: {}, context: {}, tools_used: [], tool_calls: [] }
              ]
            )
          end
        end

        def build_response(result)
          response = {
            trace: {
              id: result.trace.id,
              external_id: result.trace.external_id
            }
          }

          if result.spans.any?
            response[:spans] = result.spans.map do |span|
              { id: span.id, external_id: span.external_id }
            end
          end

          if result.llm_responses.any?
            response[:llm_responses] = result.llm_responses.map do |lr|
              { id: lr.id, external_id: lr.external_id }
            end
          end

          response
        end
      end
    end
  end
end
