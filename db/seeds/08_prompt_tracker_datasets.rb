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

  # ============================================================================
  # 3. Customer Support Conversational Dataset
  # ============================================================================
  puts "  Creating conversational datasets for multi-turn testing..."

  support_conversational_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: support_greeting_v3,
    name: "Customer Support Conversations",
    description: "Multi-turn customer support conversation scenarios",
    dataset_type: :conversational
  )

  support_conversational_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Jennifer Williams",
        "issue_category" => "billing",
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are Jennifer Williams, a frustrated customer who was charged twice for the same subscription.
          You noticed the duplicate charge on your credit card statement this morning.
          Start by explaining the issue, then ask for a refund.
          If asked for details, provide: Order IDs #78901 and #78902, both charged on January 15th for $49.99 each.
          You want both charges refunded immediately and are considering canceling your subscription.
          Be firm but professional. Accept a solution if they offer immediate refund and a discount on next month.
        PROMPT
        "max_turns" => 8
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Robert Chen",
        "issue_category" => "technical",
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are Robert Chen, a customer experiencing login issues with the mobile app.
          You've been trying to log in for the past hour but keep getting "Invalid credentials" error.
          You're certain your password is correct because it works on the website.
          Start by describing the problem. If asked, mention you're using an iPhone 15 with iOS 17.
          You've already tried restarting the app and your phone.
          Be patient and cooperative, willing to try troubleshooting steps.
          The issue should be resolved if they suggest clearing the app cache or reinstalling.
        PROMPT
        "max_turns" => 6
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "Maria Garcia",
        "issue_category" => "account",
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are Maria Garcia, trying to update your email address but the system won't let you.
          You recently got married and changed your email from maria.rodriguez@email.com to maria.garcia@email.com.
          When you try to update it in account settings, you get an error: "Email already in use."
          Start by explaining this issue. You're confused because the new email is YOUR email.
          If they ask, you created a second account by mistake with the new email last week but never used it.
          Be understanding and cooperative. Accept a solution to merge accounts or delete the unused one.
        PROMPT
        "max_turns" => 7
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "customer_name" => "David Thompson",
        "issue_category" => "refund",
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are David Thompson, requesting a refund for a premium feature you purchased but never used.
          You bought the "Pro Analytics" add-on 3 months ago for $99/month but realized you don't need it.
          You haven't used any of the pro features and want a refund for all 3 months ($297 total).
          Start by politely requesting the refund. If they mention a refund policy, you didn't see it during purchase.
          Be reasonable - you'll accept a partial refund if full refund isn't possible.
          Also want to make sure the subscription is canceled so you're not charged again.
        PROMPT
        "max_turns" => 6
      },
      source: "manual"
    }
  ])

  puts "  ✓ Created customer support conversational dataset (4 rows)"

  # ============================================================================
  # 4. Email Summary Conversational Dataset
  # ============================================================================

  email_conversational_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: email_summary_v1,
    name: "Email Summary Conversations",
    description: "Multi-turn conversations about email summarization with follow-up questions",
    dataset_type: :conversational
  )

  email_conversational_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: {
        "email_thread" => <<~EMAIL.strip,
          From: ceo@company.com
          To: leadership@company.com
          Subject: Strategic Planning Session

          Team, we need to discuss our 2026 strategy. I'm proposing a full-day offsite next month.
          Key topics: market expansion, product roadmap, and organizational changes.

          Please review the attached deck before we meet.

          ---

          From: cfo@company.com
          Subject: Re: Strategic Planning Session

          I've reviewed the financials. We should also discuss budget constraints and hiring freeze implications.

          ---

          From: cto@company.com
          Subject: Re: Strategic Planning Session

          The product roadmap looks ambitious. We'll need to prioritize given our current engineering capacity.
        EMAIL
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are an executive assistant who needs to understand this email thread to brief your manager.
          Start by asking for a summary of the email thread.
          After receiving the summary, ask follow-up questions:
          - What are the main action items?
          - Who are the key stakeholders involved?
          - What concerns were raised?
          - When is the meeting scheduled?
          Be professional and focused on extracting actionable information.
        PROMPT
        "max_turns" => 6
      },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: {
        "email_thread" => <<~EMAIL.strip,
          From: project-manager@company.com
          To: dev-team@company.com
          Subject: Sprint Review Feedback

          Hi team, great work on Sprint 23! Here's what stakeholders said:

          ✅ Loved the new dashboard UI
          ⚠️ Performance issues on mobile
          ❌ Search feature still buggy

          Let's prioritize the search fix for next sprint.

          ---

          From: lead-dev@company.com
          Subject: Re: Sprint Review Feedback

          Agreed on search priority. I'll investigate the mobile performance - might be related to the image loading.

          ---

          From: qa-lead@company.com
          Subject: Re: Sprint Review Feedback

          I've logged 3 critical bugs for search. Can we get these fixed before the demo next week?
        EMAIL
        "interlocutor_simulation_prompt" => <<~PROMPT.strip,
          You are a product manager who missed the sprint review and needs to catch up.
          Start by asking for a summary of the email thread.
          Follow up with specific questions:
          - What went well in the sprint?
          - What are the critical issues?
          - What's the plan for next sprint?
          - Are there any blockers for the upcoming demo?
          Be detail-oriented and concerned about timelines.
        PROMPT
        "max_turns" => 7
      },
      source: "manual"
    }
  ])

  puts "  ✓ Created email summary conversational dataset (2 rows)"

  # Store for use in other seed files
  SeedData.datasets = {
    support_dataset: support_dataset,
    email_dataset: email_dataset,
    support_conversational_dataset: support_conversational_dataset,
    email_conversational_dataset: email_conversational_dataset
  }

  puts "\n  ✅ Total: #{PromptTracker::Dataset.count} datasets (#{PromptTracker::Dataset.where(dataset_type: :single_turn).count} single-turn, #{PromptTracker::Dataset.where(dataset_type: :conversational).count} conversational) with #{PromptTracker::DatasetRow.count} rows"
end
