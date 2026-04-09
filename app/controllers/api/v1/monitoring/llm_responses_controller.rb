# frozen_string_literal: true

# POST /api/v1/monitoring/llm_responses
#
# Creates a single LLM response record, optionally linked to a trace/span.
# Supports referencing trace/span by either internal id or external_id.
module Api
  module V1
    module Monitoring
      class LlmResponsesController < Api::V1::BaseController
        # POST /api/v1/monitoring/llm_responses
        def create
          llm_response = PromptTracker::LlmResponse.new(llm_response_params)
          llm_response.organization = ActsAsTenant.current_tenant

          # Resolve trace by external_id if trace_id not provided
          if llm_response.trace_id.blank? && params[:llm_response][:trace_external_id].present?
            trace = PromptTracker::Trace.find_by(external_id: params[:llm_response][:trace_external_id])
            if trace.nil?
              render_error("validation_failed", "Trace not found with external_id: #{params[:llm_response][:trace_external_id]}", status: :unprocessable_entity)
              return
            end
            llm_response.trace_id = trace.id
          end

          # Resolve span by external_id if span_id not provided
          if llm_response.span_id.blank? && params[:llm_response][:span_external_id].present?
            span = PromptTracker::Span.find_by(external_id: params[:llm_response][:span_external_id])
            if span.nil?
              render_error("validation_failed", "Span not found with external_id: #{params[:llm_response][:span_external_id]}", status: :unprocessable_entity)
              return
            end
            llm_response.span_id = span.id
          end

          if llm_response.save
            render json: {
              id: llm_response.id,
              external_id: llm_response.external_id,
              status: llm_response.status,
              created_at: llm_response.created_at
            }, status: :created
          else
            render_validation_errors(llm_response)
          end
        end

        private

        def llm_response_params
          params.require(:llm_response).permit(
            :external_id,
            :trace_id,
            :span_id,
            :agent_version_id,
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
            variables_used: {},
            context: {},
            tools_used: [],
            tool_calls: []
          )
        end
      end
    end
  end
end
