# Dynamic PromptTracker Configuration PRD

**Version:** 1.0
**Date:** 2026-02-28
**Status:** Draft
**Owner:** David Geismar

---

## 1. Problem Statement

### 1.1 Current Architecture Issues

**The Core Problem:**
PromptTracker's configuration is **static and global** (singleton pattern), but our application requires **dynamic, organization-specific configuration**.

**Specific Issues:**

1. **Static Configuration Singleton**
   - `PromptTracker.configuration` is instantiated once at boot time
   - `config.providers = {}` is set once and never changes
   - Overriding methods like `api_key_for` doesn't work because the hash is already empty

2. **Organization-Specific Requirements**
   - Each organization has different API keys
   - Each organization may have different provider preferences
   - Each organization may have different context defaults (playground, llm_judge, etc.)
   - Each organization may have different feature flags

3. **Multi-Tenancy Mismatch**
   - PromptTracker expects: `ENV['OPENAI_API_KEY']` (global)
   - We have: `ApiConfiguration.where(organization: current_org)` (per-tenant)
   - Current approach sets ENV variables per-request (not thread-safe, unreliable)

4. **Configuration Scope**
   - **Providers:** Organization-specific (different API keys)
   - **Contexts:** Organization-specific (different defaults per org)
   - **Features:** Organization-specific (different feature flags per org)

### 1.2 Current Behavior

```ruby
# In console:
PromptTracker.configuration.providers
# => {} (empty hash, set at boot time)

PromptTracker.configuration.api_key_for(:openai)
# => nil (our override doesn't work because providers hash is empty)

# When user clicks "Generate" in playground:
# PromptTracker::PlaygroundController calls LlmClientService
# LlmClientService tries to get API key
# Fails because no API key found
```

---

## 2. Solution Options

### Option A: Per-Request Configuration Injection (Recommended)

**Concept:** Create a service that builds a fresh configuration object for each request based on the current organization.

**Architecture:**
```
Request → ApplicationController
  ↓
  set_current_tenant (sets ActsAsTenant.current_tenant)
  ↓
  OrganizationConfigurationService.build_for(current_organization)
  ↓
  Returns fresh PromptTracker::Configuration instance
  ↓
  Store in Thread.current[:prompttracker_config]
  ↓
  PromptTracker uses Thread.current[:prompttracker_config] || global config
```

**Pros:**
- ✅ Clean separation of concerns
- ✅ Thread-safe (each request has its own config)
- ✅ No ENV variable manipulation
- ✅ Works with background jobs (pass org_id, build config)
- ✅ Can be tested easily

**Cons:**
- ⚠️ Requires gem modification to check Thread.current
- ⚠️ Need to ensure Thread.current is cleaned up after request

**Gem Changes Required:**
```ruby
# In PromptTracker::Configuration
def self.current
  Thread.current[:prompttracker_config] || @configuration
end
```

---

### Option B: Configuration Resolver Pattern

**Concept:** Add a resolver callback to PromptTracker that's called on every config access.

**Architecture:**
```ruby
# In gem:
class Configuration
  attr_accessor :resolver

  def providers
    resolver ? resolver.call(:providers) : @providers
  end

  def api_key_for(provider)
    resolver ? resolver.call(:api_key, provider) : @providers.dig(provider, :api_key)
  end
end

# In host app:
PromptTracker.configure do |config|
  config.resolver = ->(type, *args) {
    org = ActsAsTenant.current_tenant
    case type
    when :providers
      OrganizationConfigurationService.providers_for(org)
    when :api_key
      OrganizationConfigurationService.api_key_for(org, args[0])
    end
  }
end
```

**Pros:**
- ✅ Explicit callback pattern
- ✅ Clean API
- ✅ Easy to understand

**Cons:**
- ⚠️ Requires gem modification
- ⚠️ Need to modify every config accessor

---

### Option C: Database-Backed Configuration Model

**Concept:** Create an `OrganizationConfiguration` model that mirrors PromptTracker's configuration structure.

**Architecture:**
```ruby
# app/models/organization_configuration.rb
class OrganizationConfiguration < ApplicationRecord
  belongs_to :organization

  # JSON columns:
  # - providers_config (JSON)
  # - contexts_config (JSON)
  # - features_config (JSON)

  def to_prompttracker_config
    config = PromptTracker::Configuration.new
    config.providers = build_providers_hash
    config.contexts = contexts_config
    config.features = features_config
    config
  end

  private

  def build_providers_hash
    api_keys = organization.api_configurations.active
    {
      openai: { api_key: api_keys.find_by(provider: 'openai')&.encrypted_api_key },
      anthropic: { api_key: api_keys.find_by(provider: 'anthropic')&.encrypted_api_key },
      # ...
    }.compact
  end
end
```

**Pros:**
- ✅ All configuration in database
- ✅ UI for managing contexts and features
- ✅ Audit trail of config changes
- ✅ Can version configurations

**Cons:**
- ⚠️ More complex data model
- ⚠️ Still need gem modification or Thread.current approach

---

## 3. Recommended Solution: Hybrid Approach

**Combine Option A + Option C:**

1. **Database Model:** `OrganizationConfiguration` stores all settings
2. **Service:** `OrganizationConfigurationService` builds config objects
3. **Middleware:** Sets `Thread.current[:prompttracker_config]` per-request
4. **Gem Patch:** PromptTracker checks `Thread.current` first

### 3.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Request: /orgs/acme-corp/app/prompts                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ ApplicationController                                        │
│  - set_current_tenant (ActsAsTenant.current_tenant = org)   │
│  - set_prompttracker_config (new middleware)                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ OrganizationConfigurationService.build_for(organization)    │
│  1. Fetch OrganizationConfiguration from DB                 │
│  2. Fetch ApiConfigurations (API keys)                      │
│  3. Build PromptTracker::Configuration object               │
│  4. Set providers, contexts, features                       │
│  5. Return config object                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Thread.current[:prompttracker_config] = config              │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ PromptTracker::PlaygroundController#generate                │
│  - Calls PromptTracker.configuration                        │
│  - Gets Thread.current[:prompttracker_config]               │
│  - Uses organization-specific config!                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ LlmClientService.call(provider: :openai, ...)               │
│  - Gets API key from config.api_key_for(:openai)            │
│  - Sets ENV['OPENAI_API_KEY'] = api_key                     │
│  - Calls RubyLLM.chat(model: "gpt-4o")                      │
│  - Success! ✅                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Implementation Plan

### Phase 1: Database Model (Week 1, Day 1-2)

**Tasks:**
1. Create `organization_configurations` table
2. Create `OrganizationConfiguration` model
3. Add default configuration on organization creation
4. Create migration to populate existing organizations

**Schema:**
```ruby
create_table :organization_configurations do |t|
  t.references :organization, null: false, foreign_key: true, index: { unique: true }
  t.jsonb :contexts_config, default: {}, null: false
  t.jsonb :features_config, default: {}, null: false
  t.timestamps
end
```

**Model:**
```ruby
class OrganizationConfiguration < ApplicationRecord
  belongs_to :organization

  # Validations
  validates :contexts_config, presence: true
  validates :features_config, presence: true

  # Defaults
  after_initialize :set_defaults, if: :new_record?

  def to_prompttracker_config
    # Build PromptTracker::Configuration object
  end

  private

  def set_defaults
    self.contexts_config ||= default_contexts
    self.features_config ||= default_features
  end
end
```

---

### Phase 2: Configuration Service (Week 1, Day 3-4)

**Tasks:**
1. Create `OrganizationConfigurationService`
2. Implement `build_for(organization)` method
3. Implement provider hash builder
4. Add caching layer (optional)

**Service:**
```ruby
# app/services/organization_configuration_service.rb
class OrganizationConfigurationService
  def self.build_for(organization)
    new(organization).build
  end

  def initialize(organization)
    @organization = organization
    @org_config = organization.organization_configuration || OrganizationConfiguration.new(organization: organization)
  end

  def build
    config = PromptTracker::Configuration.new
    config.providers = build_providers_hash
    config.contexts = @org_config.contexts_config.deep_symbolize_keys
    config.features = @org_config.features_config.deep_symbolize_keys
    config
  end

  private

  def build_providers_hash
    providers = {}

    @organization.api_configurations.active.each do |api_config|
      providers[api_config.provider.to_sym] = {
        api_key: api_config.encrypted_api_key
      }
    end

    providers
  end
end
```

---

### Phase 3: Middleware/Concern (Week 1, Day 5)

**Tasks:**
1. Create `SetsPromptTrackerConfig` concern
2. Include in ApplicationController
3. Set Thread.current per-request
4. Clean up Thread.current after request

**Concern:**
```ruby
# app/controllers/concerns/sets_prompt_tracker_config.rb
module SetsPromptTrackerConfig
  extend ActiveSupport::Concern

  included do
    before_action :set_prompttracker_config, if: -> { user_signed_in? && current_organization.present? }
    after_action :cleanup_prompttracker_config
  end

  private

  def set_prompttracker_config
    return unless current_organization

    config = OrganizationConfigurationService.build_for(current_organization)
    Thread.current[:prompttracker_config] = config

    # Also set ENV variables for RubyLLM
    set_env_variables_from_config(config)
  end

  def cleanup_prompttracker_config
    Thread.current[:prompttracker_config] = nil
  end

  def set_env_variables_from_config(config)
    config.providers.each do |provider, provider_config|
      env_var_name = provider_to_env_var(provider)
      ENV[env_var_name] = provider_config[:api_key] if provider_config[:api_key].present?
    end
  end

  def provider_to_env_var(provider)
    {
      openai: "OPENAI_API_KEY",
      anthropic: "ANTHROPIC_API_KEY",
      google: "GOOGLE_API_KEY",
      azure_openai: "AZURE_OPENAI_API_KEY"
    }[provider]
  end
end
```

---

### Phase 4: Gem Modification (Week 2, Day 1-2)

**Option 4A: Minimal Gem Patch (Recommended)**

Modify PromptTracker gem to check Thread.current first:

```ruby
# In PromptTracker gem: lib/prompt_tracker.rb
module PromptTracker
  def self.configuration
    # Check for thread-local config first (for multi-tenancy)
    Thread.current[:prompttracker_config] || @configuration ||= Configuration.new
  end
end
```

**Option 4B: Configuration Resolver (More Flexible)**

Add a resolver pattern to the gem:

```ruby
# In PromptTracker gem: lib/prompt_tracker/configuration.rb
class Configuration
  attr_accessor :config_resolver

  def providers
    if config_resolver
      config_resolver.call(:providers)
    else
      @providers ||= {}
    end
  end

  def api_key_for(provider)
    if config_resolver
      config_resolver.call(:api_key, provider)
    else
      providers.dig(provider.to_sym, :api_key)
    end
  end

  # Similar for contexts, features, etc.
end

# In host app:
PromptTracker.configure do |config|
  config.config_resolver = ->(type, *args) {
    org = ActsAsTenant.current_tenant
    return nil unless org

    org_config = OrganizationConfigurationService.build_for(org)

    case type
    when :providers
      org_config.providers
    when :api_key
      org_config.api_key_for(args[0])
    when :contexts
      org_config.contexts
    when :features
      org_config.features
    end
  }
end
```

**Recommendation:** Start with **Option 4A** (Thread.current check) as it's minimal and non-invasive.

---
### Phase 5: UI for Configuration Management (Week 2, Day 3-5)

**Tasks:**
1. Create `OrganizationConfigurationsController`
2. Create views for editing contexts and features
3. Add navigation link
4. Add form for context defaults
5. Add form for feature flags

**Routes:**
```ruby
scope "/orgs/:org_slug", as: :org do
  resource :configuration, only: [:show, :edit, :update], controller: :organization_configurations do
    member do
      get :contexts
      patch :update_contexts
      get :features
      patch :update_features
    end
  end
end
```

**UI Sections:**
1. **Contexts Tab:**
   - Playground defaults (provider, api, model, temperature)
   - LLM Judge defaults
   - Dataset Generation defaults
   - Prompt Generation defaults
   - Test Generation defaults

2. **Features Tab:**
   - OpenAI Assistant Sync (toggle)
   - Future feature flags

---

## 5. Migration Strategy

### 5.1 Backward Compatibility

**During Transition:**
1. Keep existing `config/initializers/prompt_tracker.rb` as fallback
2. If `Thread.current[:prompttracker_config]` is nil, use global config
3. Gradually migrate organizations to database config

**Fallback Logic:**
```ruby
# In gem:
def self.configuration
  Thread.current[:prompttracker_config] || @configuration ||= Configuration.new
end
```

### 5.2 Data Migration

**Step 1:** Create `organization_configurations` table

**Step 2:** Populate with defaults:
```ruby
Organization.find_each do |org|
  OrganizationConfiguration.create!(
    organization: org,
    contexts_config: OrganizationConfiguration::DEFAULT_CONTEXTS,
    features_config: OrganizationConfiguration::DEFAULT_FEATURES
  )
end
```

**Step 3:** Remove old initializer approach

---

## 6. Testing Strategy

### 6.1 Unit Tests

```ruby
# spec/services/organization_configuration_service_spec.rb
RSpec.describe OrganizationConfigurationService do
  let(:organization) { create(:organization) }
  let!(:api_config) { create(:api_configuration, organization: organization, provider: :openai) }

  describe '.build_for' do
    it 'builds a PromptTracker::Configuration with organization API keys' do
      config = described_class.build_for(organization)

      expect(config).to be_a(PromptTracker::Configuration)
      expect(config.providers[:openai][:api_key]).to eq(api_config.encrypted_api_key)
    end
  end
end
```

### 6.2 Integration Tests

```ruby
# spec/requests/prompt_tracker/playground_spec.rb
RSpec.describe "PromptTracker Playground", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let!(:api_config) { create(:api_configuration, organization: organization, provider: :openai, encrypted_api_key: "sk-test-123") }

  before do
    sign_in user
    organization.users << user
  end

  it 'uses organization-specific API key' do
    get "/orgs/#{organization.slug}/app/playground"

    # Verify Thread.current has the right config
    expect(Thread.current[:prompttracker_config]).to be_present
    expect(Thread.current[:prompttracker_config].api_key_for(:openai)).to eq("sk-test-123")
  end
end
```

---

## 7. Rollout Plan

### Week 1: Foundation
- ✅ Day 1-2: Create database model and migration
- ✅ Day 3-4: Build configuration service
- ✅ Day 5: Create middleware/concern

### Week 2: Integration
- ✅ Day 1-2: Modify PromptTracker gem (submit PR)
- ✅ Day 3-5: Build UI for configuration management

### Week 3: Testing & Refinement
- ✅ Day 1-2: Write comprehensive tests
- ✅ Day 3-4: Test with real API keys and LLM calls
- ✅ Day 5: Documentation and cleanup

---

## 8. Success Criteria

1. ✅ Each organization can have different API keys
2. ✅ Each organization can configure context defaults
3. ✅ Each organization can enable/disable features
4. ✅ LLM calls use the correct organization's API key
5. ✅ No cross-tenant data leakage
6. ✅ Thread-safe in multi-threaded environment
7. ✅ Works in background jobs (with explicit org_id)
8. ✅ UI for managing all configuration settings

---

## 9. Open Questions

1. **Caching:** Should we cache configuration objects? For how long?
2. **Validation:** Should we validate API keys when saving configuration?
3. **Defaults:** What should happen if an organization has no configuration?
4. **Background Jobs:** How do we pass organization context to Sidekiq?
5. **Gem Ownership:** Do we fork PromptTracker or submit PR upstream?

---

## 10. Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Thread.current not cleaned up | Memory leak | Use after_action to cleanup |
| Gem modification rejected | Can't use Thread.current | Use resolver pattern instead |
| Performance impact | Slow requests | Cache config objects per-request |
| Background jobs fail | No tenant context | Pass org_id explicitly to jobs |

---
## 11. Appendix: Full Request Flow Example

```ruby
# 1. User visits playground
GET /orgs/acme-corp/app/playground

# 2. ApplicationController runs before_actions
before_action :authenticate_user!
before_action :set_current_tenant  # Sets ActsAsTenant.current_tenant
before_action :set_prompttracker_config  # NEW!

# 3. set_prompttracker_config runs
def set_prompttracker_config
  config = OrganizationConfigurationService.build_for(current_organization)
  # config.providers = { openai: { api_key: "sk-acme-123" } }
  # config.contexts = { playground: { default_provider: :openai, ... } }
  # config.features = { openai_assistant_sync: true }

  Thread.current[:prompttracker_config] = config
  ENV['OPENAI_API_KEY'] = config.api_key_for(:openai)
end

# 4. PromptTracker::PlaygroundController#show renders
# Uses PromptTracker.configuration (gets Thread.current config)

# 5. User clicks "Generate"
POST /orgs/acme-corp/app/playground/generate

# 6. PromptTracker::PlaygroundController#generate
def generate
  response = LlmClientService.call(
    provider: params[:provider],  # :openai
    model: params[:model],        # "gpt-4o"
    prompt: params[:prompt]
  )
end

# 7. LlmClientService.call
def self.call(provider:, model:, prompt:, ...)
  # Gets API key from configuration
  api_key = PromptTracker.configuration.api_key_for(provider)
  # api_key = "sk-acme-123" (from Thread.current config!)

  # Sets ENV variable
  ENV['OPENAI_API_KEY'] = api_key

  # Calls RubyLLM
  chat = RubyLLM.chat(model: model)
  response = chat.ask(prompt)
  # Success! ✅
end

# 8. after_action cleanup
def cleanup_prompttracker_config
  Thread.current[:prompttracker_config] = nil
end
```

---

## 12. Recommendation & Next Steps

### 12.1 Recommended Approach

**I recommend implementing the Hybrid Approach (Option A + C):**

1. **Short-term (This Week):**
   - Create `OrganizationConfiguration` model
   - Create `OrganizationConfigurationService`
   - Create `SetsPromptTrackerConfig` concern
   - Modify PromptTracker gem to check `Thread.current` first

2. **Medium-term (Next Week):**
   - Build UI for managing contexts and features
   - Add comprehensive tests
   - Submit PR to PromptTracker gem

3. **Long-term (Future):**
   - Add caching layer for performance
   - Add API key validation
   - Add configuration versioning/audit trail

**This approach:**
- ✅ Solves the immediate problem (organization-specific API keys)
- ✅ Is thread-safe and works with Puma
- ✅ Allows UI for managing all configuration
- ✅ Minimal gem changes (just one line!)
- ✅ Can be tested incrementally

### 12.2 Implementation Priority

**Phase 1 (Critical - Do First):**
1. Modify PromptTracker gem (`lib/prompt_tracker.rb`)
2. Create `OrganizationConfiguration` model
3. Create `OrganizationConfigurationService`
4. Replace `SetsLlmApiKeys` with `SetsPromptTrackerConfig`

**Phase 2 (Important - Do Next):**
1. Build UI for contexts configuration
2. Build UI for features configuration
3. Add tests

**Phase 3 (Nice to Have - Do Later):**
1. Add caching
2. Add validation
3. Add audit trail

---

## 13. Summary

**The Problem:**
- PromptTracker configuration is static/global
- We need dynamic, per-organization configuration
- Current ENV variable approach doesn't work

**The Solution:**
- Store configuration in database (`OrganizationConfiguration`)
- Build config object per-request (`OrganizationConfigurationService`)
- Store in Thread.current (`SetsPromptTrackerConfig` concern)
- Modify gem to check Thread.current first (one-line change!)

**The Outcome:**
- Each organization has its own API keys, contexts, and features
- Thread-safe and multi-tenant
- Clean separation of concerns
- Minimal gem modification

---

**Ready to implement? Let me know and I'll start with Phase 1!** 🚀
