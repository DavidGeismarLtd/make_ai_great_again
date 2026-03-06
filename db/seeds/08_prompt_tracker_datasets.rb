# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - DATASETS
# ============================================================================
puts "\n📊 Creating PromptTracker datasets..."

acme_corp = SeedData.organizations[:acme_corp]
support_greeting_v2 = SeedData.prompt_versions[:support_greeting_v2]

ActsAsTenant.with_tenant(acme_corp) do
  support_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: support_greeting_v2,
    name: "Customer Support Test Cases",
    description: "Common customer support scenarios",
    dataset_type: :single_turn  # 0=single_turn, 1=conversational
  )

  support_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "John Smith", issue_category: "billing" },
      metadata: { priority: "high" },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "Sarah Johnson", issue_category: "technical" },
      metadata: { priority: "medium" },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "Mike Davis", issue_category: "account" },
      metadata: { priority: "low" },
      source: "manual"
    }
  ])

  puts "  ✓ Created #{PromptTracker::Dataset.count} datasets with #{PromptTracker::DatasetRow.count} rows"
end

