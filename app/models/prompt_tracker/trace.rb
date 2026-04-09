# frozen_string_literal: true

# PromptTracker::Trace
#
# Represents a distributed trace for tracking LLM pipelines.
# A trace groups related spans together and provides high-level
# visibility into an entire LLM workflow execution.
#
# The gem does not ship this model, so it's defined in the host app.
module PromptTracker
  class Trace < PromptTracker::ApplicationRecord
    self.table_name = "prompt_tracker_traces"

    # Associations
    has_many :spans, class_name: "PromptTracker::Span", dependent: :destroy, foreign_key: :trace_id
    has_many :llm_responses, class_name: "PromptTracker::LlmResponse", foreign_key: :trace_id

    # Validations
    validates :name, presence: true
    validates :status, presence: true, inclusion: { in: %w[running completed error] }
    validates :started_at, presence: true

    validates :duration_ms,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 },
              allow_nil: true

    validate :metadata_must_be_hash

    # Scopes
    scope :running, -> { where(status: "running") }
    scope :completed, -> { where(status: "completed") }
    scope :errored, -> { where(status: "error") }
    scope :for_session, ->(session_id) { where(session_id: session_id) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :recent, ->(hours = 24) { where("created_at > ?", hours.hours.ago) }

    private

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
