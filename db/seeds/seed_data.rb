# frozen_string_literal: true

# SeedData - Simple data store for sharing data between seed files
# This allows us to split seeds into multiple files while maintaining references
class SeedData
  class << self
    attr_accessor :organizations, :users, :prompt_versions

    def reset!
      @organizations = {}
      @users = {}
      @prompt_versions = {}
    end
  end
end

# Initialize
SeedData.reset!

