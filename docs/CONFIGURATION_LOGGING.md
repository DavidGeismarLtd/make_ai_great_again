# Configuration & API Key Logging

This document explains the logging system for tracking LLM provider configuration and API key usage across organizations.

## Overview

The application logs detailed information about:
1. **Organization context** - Which organization is being used for each request
2. **API key loading** - Which API keys are loaded from the database
3. **ENV variable setting** - Which environment variables are set for LLM providers
4. **Configuration provider** - When PromptTracker configuration is built

## Log Format

All logs are prefixed with identifiable tags:
- `[PromptTracker Config]` - Configuration provider logs
- `[LLM API Keys]` - ENV variable setting logs
- Request tags include: `request_id` and `org:slug`

## Security

**API keys are masked in logs** to prevent exposure:
- Format: `sk-proj...xyz` (first 7 chars + last 4 chars)
- Example: `sk-proj-abc123...xyz9`
- Keys shorter than 10 characters are shown as-is (for testing)
- Null/empty keys are shown as `nil` or `empty`

## Log Examples

### Successful Configuration Loading

```
[request_id] [org:acme-corp] [PromptTracker Config] =========================================
[request_id] [org:acme-corp] [PromptTracker Config] Building configuration for organization: Acme Corp (acme-corp)
[request_id] [org:acme-corp] [PromptTracker Config] =========================================
[request_id] [org:acme-corp] [PromptTracker Config] Loading providers for organization: Acme Corp (ID: 1, Slug: acme-corp)
[request_id] [org:acme-corp] [PromptTracker Config] Found 2 active API configuration(s)
[request_id] [org:acme-corp] [PromptTracker Config]   - Provider: openai, Key Name: Production Key, API Key: sk-proj...abc1
[request_id] [org:acme-corp] [PromptTracker Config]   - Provider: anthropic, Key Name: Production Key, API Key: sk-ant-...xyz9
[request_id] [org:acme-corp] [PromptTracker Config] Configuration built successfully
[request_id] [org:acme-corp] [PromptTracker Config] =========================================
```

### ENV Variable Setting

```
[request_id] [org:acme-corp] [LLM API Keys] =========================================
[request_id] [org:acme-corp] [LLM API Keys] Setting ENV variables for organization: Acme Corp (ID: 1, Slug: acme-corp)
[request_id] [org:acme-corp] [LLM API Keys] Request: GET /orgs/acme-corp/app/testing
[request_id] [org:acme-corp] [LLM API Keys] =========================================
[request_id] [org:acme-corp] [LLM API Keys] Found 2 active API configuration(s)
[request_id] [org:acme-corp] [LLM API Keys]   ✓ Set OPENAI_API_KEY = sk-proj...abc1 (from: Production Key)
[request_id] [org:acme-corp] [LLM API Keys]   ✓ Set ANTHROPIC_API_KEY = sk-ant-...xyz9 (from: Production Key)
[request_id] [org:acme-corp] [LLM API Keys] =========================================
```

### No Tenant Set (Console/Background Jobs)

```
[PromptTracker Config] No current tenant set - using static fallback configuration
```

### Missing API Keys Warning

```
[request_id] [org:new-org] [PromptTracker Config] ⚠️  No active API configurations found for organization: New Org
[request_id] [org:new-org] [LLM API Keys] ⚠️  No active API configurations found - ENV variables not set
```

### Empty API Key Warning

```
[request_id] [org:test-org] [LLM API Keys]   ✗ Skipped OPENAI_API_KEY - API key is empty (config: Test Key)
```

## Viewing Logs

### Development

Logs are output to STDOUT (your terminal):

```bash
# Start the server
bin/rails server

# Logs will appear in the terminal as requests are processed
```

### Production

Logs are sent to STDOUT and captured by your hosting platform:

**Render.com:**
```bash
# View live logs
render logs -t

# Or in the Render dashboard: Services > Your App > Logs
```

**Heroku:**
```bash
heroku logs --tail --app your-app-name
```

**Docker/Kamal:**
```bash
kamal app logs -f
```

### Filtering Logs

**Find all configuration logs:**
```bash
# Development
tail -f log/development.log | grep "PromptTracker Config"

# Production (Render)
render logs -t | grep "PromptTracker Config"
```

**Find logs for specific organization:**
```bash
# Development
tail -f log/development.log | grep "org:acme-corp"

# Production (Render)
render logs -t | grep "org:acme-corp"
```

**Find API key setting logs:**
```bash
tail -f log/development.log | grep "LLM API Keys"
```

## Debugging Common Issues

### Issue: "No active API configurations found"

**Cause:** Organization has no API keys configured in the database.

**Solution:**
1. Go to `/orgs/your-org/api_configurations`
2. Add API keys for the providers you need
3. Ensure `is_active` is set to `true`

### Issue: "No current tenant set"

**Cause:** Request is not scoped to an organization (e.g., console, background job).

**Solution:**
- In console: Use `ActsAsTenant.with_tenant(org) { ... }`
- In background jobs: Ensure tenant is set via Sidekiq integration

### Issue: API calls failing despite keys being set

**Check the logs for:**
1. Is the correct organization being used? (check `org:slug` tag)
2. Are the API keys being loaded? (check for masked key in logs)
3. Are ENV variables being set? (check for `✓ Set OPENAI_API_KEY`)
4. Is the key masked correctly? (should show first 7 + last 4 chars)

## Log Levels

The application uses Rails standard log levels:

- **INFO** - Normal configuration loading and API key setting
- **WARN** - Missing configurations or empty keys
- **ERROR** - Configuration errors (not currently used, but available)

To change log level in production:
```bash
# Set via environment variable
RAILS_LOG_LEVEL=debug
```

## Privacy & Security

✅ **Safe to share logs** - API keys are always masked
✅ **Production-ready** - Logging is enabled in all environments
✅ **Performance** - Minimal overhead (only logs on request start)
⚠️ **Do not log full API keys** - Always use the masking functions

## Related Files

- `config/initializers/prompt_tracker.rb` - Configuration provider with logging
- `app/controllers/concerns/sets_llm_api_keys.rb` - ENV variable setting with logging
- `config/environments/production.rb` - Production logging configuration
- `config/environments/development.rb` - Development logging configuration

