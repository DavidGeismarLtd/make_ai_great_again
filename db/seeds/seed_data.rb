# frozen_string_literal: true

# SeedData - Simple data store for sharing data between seed files
# This allows us to split seeds into multiple files while maintaining references
class SeedData
  class << self
    attr_accessor :organizations, :users, :prompt_versions, :tests, :datasets, :monitoring_api_keys, :function_definitions

    def reset!
      @organizations = {}
      @users = {}
      @prompt_versions = {}
      @tests = {}
      @datasets = {}
      @monitoring_api_keys = {}
      @function_definitions = {}
    end
  end
end

# Initialize
SeedData.reset!
