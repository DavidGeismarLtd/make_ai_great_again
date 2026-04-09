# frozen_string_literal: true

# ============================================================================
# FUNCTION DEFINITIONS
# ============================================================================
puts "\n⚡ Creating Function Definitions..."

acme_corp = SeedData.organizations[:acme_corp]
tech_startup = SeedData.organizations[:tech_startup]

# --- Acme Corp functions ---
ActsAsTenant.with_tenant(acme_corp) do
  get_weather = PromptTracker::FunctionDefinition.create!(
    name: "get_weather",
    description: "Fetches current weather data for a given city using the OpenWeatherMap API.",
    category: "api",
    language: "ruby",
    tags: %w[weather api external],
    created_by: "admin@example.com",
    code: <<~RUBY,
      def execute(city:, units: "metric")
        api_key = env['OPENWEATHER_API_KEY']
        response = HTTP.get("https://api.openweathermap.org/data/2.5/weather",
          params: { q: city, units: units, appid: api_key })
        JSON.parse(response.body)
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "city" => { "type" => "string", "description" => "City name" },
        "units" => { "type" => "string", "enum" => %w[metric imperial] }
      },
      "required" => ["city"]
    },
    example_input: { "city" => "Paris", "units" => "metric" },
    example_output: { "temp" => 18.5, "description" => "partly cloudy" },
    dependencies: ["http"]
  )

  search_kb = PromptTracker::FunctionDefinition.create!(
    name: "search_knowledge_base",
    description: "Searches the internal knowledge base using semantic similarity.",
    category: "retrieval",
    language: "ruby",
    tags: %w[search rag knowledge-base],
    created_by: "admin@example.com",
    code: <<~RUBY,
      def execute(query:, top_k: 5)
        results = VectorDB.search(collection: "knowledge_base", query: query, limit: top_k)
        results.map { |r| { title: r.title, content: r.content, score: r.score } }
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "query" => { "type" => "string", "description" => "Search query" },
        "top_k" => { "type" => "integer", "description" => "Number of results", "default" => 5 }
      },
      "required" => ["query"]
    },
    example_input: { "query" => "How do I reset my password?", "top_k" => 3 },
    example_output: [{ "title" => "Password Reset Guide", "score" => 0.95 }]
  )

  send_email = PromptTracker::FunctionDefinition.create!(
    name: "send_email",
    description: "Sends an email via the SendGrid API.",
    category: "communication",
    language: "ruby",
    tags: %w[email notification sendgrid],
    created_by: "admin@example.com",
    code: <<~RUBY,
      def execute(to:, subject:, body:, from: nil)
        api_key = env['SENDGRID_API_KEY']
        from_addr = from || env['DEFAULT_FROM_EMAIL']
        response = HTTP.auth("Bearer \#{api_key}")
          .post("https://api.sendgrid.com/v3/mail/send", json: {
            personalizations: [{ to: [{ email: to }] }],
            from: { email: from_addr },
            subject: subject,
            content: [{ type: "text/plain", value: body }]
          })
        { status: response.status }
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "to" => { "type" => "string", "description" => "Recipient email" },
        "subject" => { "type" => "string", "description" => "Email subject" },
        "body" => { "type" => "string", "description" => "Email body" },
        "from" => { "type" => "string", "description" => "Sender (optional)" }
      },
      "required" => %w[to subject body]
    },
    example_input: { "to" => "user@example.com", "subject" => "Hello", "body" => "Hi!" },
    example_output: { "status" => 202 }
  )

  calc_price = PromptTracker::FunctionDefinition.create!(
    name: "calculate_price",
    description: "Calculates total price including tax and discounts.",
    category: "business_logic",
    language: "ruby",
    tags: %w[pricing calculation math],
    created_by: "admin@example.com",
    code: <<~RUBY,
      def execute(items:, tax_rate: 0.20, discount_code: nil)
        subtotal = items.sum { |i| i["price"] * i["quantity"] }
        discount = discount_code ? apply_discount(subtotal, discount_code) : 0
        tax = (subtotal - discount) * tax_rate
        { subtotal: subtotal.round(2), discount: discount.round(2),
          tax: tax.round(2), total: (subtotal - discount + tax).round(2) }
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "items" => {
          "type" => "array", "description" => "Items with price and quantity",
          "items" => { "type" => "object", "properties" => {
            "name" => { "type" => "string" },
            "price" => { "type" => "number" },
            "quantity" => { "type" => "integer" } } }
        },
        "tax_rate" => { "type" => "number", "description" => "Tax rate" },
        "discount_code" => { "type" => "string", "description" => "Discount code" }
      },
      "required" => ["items"]
    },
    example_input: { "items" => [{ "name" => "Widget", "price" => 9.99, "quantity" => 2 }] },
    example_output: { "subtotal" => 19.98, "tax" => 4.0, "total" => 23.98 }
  )

  puts "  ✓ Acme Corp: Created 4 function definitions"
  SeedData.function_definitions.merge!(
    get_weather: get_weather, search_knowledge_base: search_kb,
    send_email: send_email, calculate_price: calc_price
  )
end

# --- Tech Startup functions ---
ActsAsTenant.with_tenant(tech_startup) do
  lookup_user = PromptTracker::FunctionDefinition.create!(
    name: "lookup_user",
    description: "Looks up a user by email or ID and returns their profile.",
    category: "database",
    language: "ruby",
    tags: %w[user database lookup],
    created_by: "demo@example.com",
    code: <<~RUBY,
      def execute(identifier:, by: "email")
        case by
        when "email"
          User.find_by(email: identifier)&.as_json(only: [:id, :name, :email, :plan])
        when "id"
          User.find_by(id: identifier)&.as_json(only: [:id, :name, :email, :plan])
        else
          { error: "Invalid lookup field: \#{by}" }
        end
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "identifier" => { "type" => "string", "description" => "User email or ID" },
        "by" => { "type" => "string", "enum" => %w[email id], "default" => "email" }
      },
      "required" => ["identifier"]
    },
    example_input: { "identifier" => "user@example.com", "by" => "email" },
    example_output: { "id" => 42, "name" => "Jane Doe", "email" => "user@example.com", "plan" => "pro" }
  )

  create_ticket = PromptTracker::FunctionDefinition.create!(
    name: "create_support_ticket",
    description: "Creates a support ticket in the helpdesk system.",
    category: "support",
    language: "ruby",
    tags: %w[support ticket helpdesk],
    created_by: "demo@example.com",
    code: <<~RUBY,
      def execute(subject:, description:, priority: "medium", customer_email: nil)
        ticket = {
          subject: subject,
          description: description,
          priority: priority,
          customer_email: customer_email,
          status: "open",
          created_at: Time.current.iso8601
        }
        ticket.merge(id: SecureRandom.hex(4))
      end
    RUBY
    parameters: {
      "type" => "object",
      "properties" => {
        "subject" => { "type" => "string", "description" => "Ticket subject" },
        "description" => { "type" => "string", "description" => "Issue description" },
        "priority" => { "type" => "string", "enum" => %w[low medium high urgent] },
        "customer_email" => { "type" => "string", "description" => "Customer email" }
      },
      "required" => %w[subject description]
    },
    example_input: { "subject" => "Cannot login", "description" => "403 error", "priority" => "high" },
    example_output: { "id" => "a1b2c3d4", "subject" => "Cannot login", "status" => "open" }
  )

  puts "  ✓ Tech Startup: Created 2 function definitions"
  SeedData.function_definitions.merge!(
    lookup_user: lookup_user, create_ticket: create_ticket
  )
end

total = ActsAsTenant.without_tenant { PromptTracker::FunctionDefinition.count }
puts "  ✅ Total: #{total} function definitions"
