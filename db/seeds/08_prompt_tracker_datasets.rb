# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - DATASETS & ROWS
# ============================================================================
puts "\n📊 Creating PromptTracker datasets and rows..."

acme_corp = SeedData.organizations[:acme_corp]

# Set tenant context for PromptTracker data creation
ActsAsTenant.with_tenant(acme_corp) do
  # Get prompt versions
  support_greeting_v3 = SeedData.prompt_versions[:support_greeting_v3]
  email_summary_v1 = SeedData.prompt_versions[:email_summary_v1]
  code_review_v1 = SeedData.prompt_versions[:code_review_v1]

  # ============================================================================
  # 1. Customer Support Greeting Dataset
  # ============================================================================
  puts "  Creating customer support datasets..."

  support_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: support_greeting_v3,
    name: "Customer Scenarios",
    description: "Common customer support scenarios for testing greetings"
  )

  support_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "John Smith",
        "issue_category" => "billing"
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Sarah Johnson",
        "issue_category" => "technical"
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Mike Davis",
        "issue_category" => "account"
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Emily Chen",
        "issue_category" => "general"
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Alex Martinez",
        "issue_category" => "refund"
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Jennifer Williams",
        "issue_category" => "refund"
      },
      source: "manual"
    }
  ])

  puts "  ✓ Created customer support dataset (6 rows)"

  # ============================================================================
  # 2. Email Summary Generator Dataset
  # ============================================================================
  puts "  Creating email summary datasets..."

  email_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: email_summary_v1,
    name: "Email Threads",
    description: "Sample email threads for testing summarization"
  )

  email_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: {
        "email_thread" => <<~EMAIL.strip
          From: alice@example.com
          To: team@example.com
          Subject: Q4 Planning Meeting

          Hi team,

          I'd like to schedule our Q4 planning meeting for next week.
          We need to discuss budget allocation and project priorities.

          Best,
          Alice

          ---

          From: bob@example.com
          To: alice@example.com, team@example.com
          Subject: Re: Q4 Planning Meeting

          Tuesday or Wednesday works for me. I'll prepare the budget report.

          Bob

          ---

          From: carol@example.com
          To: alice@example.com, team@example.com
          Subject: Re: Q4 Planning Meeting

          Wednesday is better for me. I'll have the project status updates ready.

          Carol
        EMAIL
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "email_thread" => <<~EMAIL.strip
          From: support@vendor.com
          To: procurement@company.com
          Subject: Contract Renewal

          Dear Customer,

          Your annual contract expires on December 31st.
          We're offering a 15% discount for early renewal.

          Best regards,
          Vendor Support

          ---

          From: procurement@company.com
          To: support@vendor.com
          Subject: Re: Contract Renewal

          Thank you. We'd like to discuss the renewal terms.
          Can we schedule a call for next week?

          Regards,
          Procurement Team
        EMAIL
      },
      source: "manual"
    }
  ])

  puts "  ✓ Created email summary dataset (2 rows)"

  # Store for use in other seed files
  SeedData.datasets = {
    support_dataset: support_dataset,
    email_dataset: email_dataset
  }

  puts "\n  ✅ Total: #{PromptTracker::Dataset.count} datasets with #{PromptTracker::DatasetRow.count} rows"
end

