# Database Seeds

This directory contains modular seed files for the MakeAiGreatAgain application.

## Structure

The seed files are organized by domain and loaded in a specific order to respect dependencies:

1. **seed_data.rb** - Helper class for sharing data between seed files
2. **01_cleanup.rb** - Removes existing data (respects foreign key constraints)
3. **02_organizations.rb** - Creates organizations (Acme Corp, Tech Startup, Default)
4. **03_users.rb** - Creates users (admin, demo)
5. **04_organization_memberships.rb** - Links users to organizations
6. **05_api_configurations.rb** - Creates API keys for LLM providers
7. **06_prompt_tracker_prompts.rb** - Creates PromptTracker prompts and versions
8. **07_prompt_tracker_tests.rb** - Creates tests and evaluator configs
9. **08_prompt_tracker_datasets.rb** - Creates datasets and dataset rows

## Usage

Run all seeds:
```bash
rails db:seed
```

Run a specific seed file (for development):
```bash
rails runner "require_relative 'db/seeds/seed_data'; require_relative 'db/seeds/06_prompt_tracker_prompts'"
```

## Adding New Seed Files

1. Create a new file with a numeric prefix (e.g., `09_new_feature.rb`)
2. Add it to the `seed_files` array in `db/seeds.rb`
3. Use `SeedData` class to access data from previous seed files:
   ```ruby
   acme_corp = SeedData.organizations[:acme_corp]
   admin_user = SeedData.users[:admin]
   ```
4. Store data for use in later seed files:
   ```ruby
   SeedData.my_new_data = { key: value }
   ```

## Data Sharing

The `SeedData` class provides a simple way to share data between seed files:

- `SeedData.organizations` - Hash of created organizations
- `SeedData.users` - Hash of created users
- `SeedData.prompt_versions` - Hash of created prompt versions

## Multi-Tenancy

PromptTracker seed files wrap data creation in `ActsAsTenant.with_tenant` blocks to ensure proper tenant context for URL generation and data isolation.

## Environment Variables

Some seed files use environment variables for API keys:
- `OPENAI_API_KEY` - OpenAI API key (falls back to placeholder)
- `ANTHROPIC_API_KEY` - Anthropic API key (falls back to placeholder)

