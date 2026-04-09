# frozen_string_literal: true

# SeedData - Simple data store for sharing data between seed files
# This allows us to split seeds into multiple files while maintaining references
class SeedData
  class << self
    attr_accessor :organizations, :users, :prompt_versions, :tests, :datasets, :monitoring_api_keys

    def reset!
      @organizations = {}
      @users = {}
      @prompt_versions = {}
      @tests = {}
      @datasets = {}
      @monitoring_api_keys = {}
    end
  end
end

# Initialize
SeedData.reset!
# curl -X POST http://localhost:3000/api/v1/monitoring/ingest \
#   -H "Authorization: Bearer pt_mon_562896d66d1622e7a9d7855c093e983bb21dd4014146a87c92145e3893e65481" \
#   -H "Content-Type: application/json" \
#   -d '{
#     "trace": {
#       "external_id": "my-trace-1",
#       "name": "my-pipeline",
#       "status": "completed",
#       "started_at": "2026-04-09T10:00:00Z"
#     }
#   }'
