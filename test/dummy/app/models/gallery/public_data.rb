module Gallery
  module PublicData
    Plan = ::Data.define(:id, :name, :monthly_cents, :annual_cents, :description, :features, :highlighted)
    Feature = ::Data.define(:id, :category, :title, :description)
    Proof = ::Data.define(:id, :organization, :result, :detail)
    SystemStatus = ::Data.define(
      :state,
      :code,
      :title,
      :description,
      :variant,
      :icon,
      :primary_action,
      :primary_href,
      :secondary_action,
      :secondary_href,
      :reference,
      :retry_after
    )
    CheckoutOutcome = ::Data.define(
      :state,
      :title,
      :description,
      :variant,
      :icon,
      :reference,
      :amount,
      :next_step,
      :action,
      :href
    )

    PLANS = [
      Plan.new(
        id: "starter",
        name: "Starter",
        monthly_cents: 0,
        annual_cents: 0,
        description: "A small workspace for evaluating typed Rails interfaces.",
        features: [ "One workspace", "Three members", "Community support" ].freeze,
        highlighted: false
      ),
      Plan.new(
        id: "team",
        name: "Team",
        monthly_cents: 4_900,
        annual_cents: 49_000,
        description: "Production collaboration for growing application teams.",
        features: [ "Unlimited workspaces", "Twenty members", "Email support" ].freeze,
        highlighted: true
      ),
      Plan.new(
        id: "scale",
        name: "Scale",
        monthly_cents: 12_900,
        annual_cents: 129_000,
        description: "Governance, security, and support for regulated operations.",
        features: [ "Unlimited members", "730-day audit history", "Priority support" ].freeze,
        highlighted: false
      )
    ].freeze

    FEATURES = [
      Feature.new(
        id: "typed-components",
        category: :foundation,
        title: "Typed Ruby components",
        description: "Closed Phlex APIs make component vocabulary explicit and verifiable."
      ),
      Feature.new(
        id: "static-css",
        category: :foundation,
        title: "Static, themeable CSS",
        description: "Gem-owned styles use documented custom properties without runtime compilation."
      ),
      Feature.new(
        id: "rails-forms",
        category: :automation,
        title: "Rails-native forms",
        description: "Model values, errors, names, multipart behavior, and submission semantics stay intact."
      ),
      Feature.new(
        id: "hotwire",
        category: :automation,
        title: "Hotwire-ready behavior",
        description: "Small Stimulus controllers preserve native controls and Turbo lifecycle safety."
      ),
      Feature.new(
        id: "accessible-contracts",
        category: :security,
        title: "Visible interface contracts",
        description: "Native semantics and stable data attributes make accessibility structure inspectable."
      ),
      Feature.new(
        id: "application-ownership",
        category: :collaboration,
        title: "Application-owned product logic",
        description: "Routes, models, authorization, data, and business decisions remain in the Rails app."
      )
    ].freeze

    PROOF = [
      Proof.new(
        id: "analytical-engines",
        organization: "Analytical Engines",
        result: "42% fewer interface regressions",
        detail: "A single typed vocabulary replaced six project-specific component wrappers."
      ),
      Proof.new(
        id: "orbital-research",
        organization: "Orbital Research",
        result: "18 production flows verified",
        detail: "Agents compose Rails screens from the same documented components engineers review."
      ),
      Proof.new(
        id: "north-sea-systems",
        organization: "North Sea Systems",
        result: "Zero runtime styling dependencies",
        detail: "Static CSS ships with the gem and adapts through organization theme variables."
      )
    ].freeze

    SYSTEM_STATUSES = [
      SystemStatus.new(
        state: "403",
        code: "403",
        title: "You do not have access to this page",
        description: "Your account is signed in, but the application policy does not permit this operation.",
        variant: :warning,
        icon: :lock,
        primary_action: "Return to workspace",
        primary_href: "/gallery",
        secondary_action: "Request access",
        secondary_href: "#request-access",
        reference: "policy_denied_2048",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "404",
        code: "404",
        title: "We could not find that page",
        description: "The address may be outdated, or the resource may have moved.",
        variant: :default,
        icon: :search_x,
        primary_action: "Go to the homepage",
        primary_href: "/gallery",
        secondary_action: "Visit help center",
        secondary_href: "#help",
        reference: "route_not_found_2048",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "422",
        code: "422",
        title: "The request could not be processed",
        description: "The submitted values are valid HTML, but they conflict with the current application state.",
        variant: :warning,
        icon: :triangle_alert,
        primary_action: "Review the request",
        primary_href: "#review-request",
        secondary_action: "Return to workspace",
        secondary_href: "/gallery",
        reference: "unprocessable_change_2048",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "500",
        code: "500",
        title: "Something went wrong",
        description: "The application recorded the failure. No submitted data was intentionally changed.",
        variant: :error,
        icon: :circle_x,
        primary_action: "Try again",
        primary_href: "#retry",
        secondary_action: "View system status",
        secondary_href: "#status",
        reference: "server_error_2048",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "maintenance",
        code: "Maintenance",
        title: "Scheduled maintenance is in progress",
        description: "Workspace writes are paused while the database is upgraded. Existing data remains protected.",
        variant: :default,
        icon: :clock_alert,
        primary_action: "View maintenance updates",
        primary_href: "#maintenance-updates",
        secondary_action: "Contact support",
        secondary_href: "#support",
        reference: "maintenance_2026_07_13",
        retry_after: "11:30 UTC"
      ),
      SystemStatus.new(
        state: "offline",
        code: "Offline",
        title: "You appear to be offline",
        description: "Reconnect to the internet, then retry. Unsaved browser values remain on this page.",
        variant: :warning,
        icon: :triangle_alert,
        primary_action: "Retry connection",
        primary_href: "#retry-connection",
        secondary_action: "Return to workspace",
        secondary_href: "/gallery",
        reference: "browser_offline",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "rate-limited",
        code: "429",
        title: "Too many requests",
        description: "The application temporarily limited this client to protect shared service capacity.",
        variant: :warning,
        icon: :clock_alert,
        primary_action: "Retry after 42 seconds",
        primary_href: "#retry-later",
        secondary_action: "Read API limits",
        secondary_href: "#api-limits",
        reference: "rate_limit_api_2048",
        retry_after: "42 seconds"
      ),
      SystemStatus.new(
        state: "degraded",
        code: "Degraded",
        title: "Some services are responding slowly",
        description: "Core workspace access is available while webhook delivery and exports recover.",
        variant: :warning,
        icon: :activity,
        primary_action: "View incident updates",
        primary_href: "#incident-updates",
        secondary_action: "Continue to workspace",
        secondary_href: "/gallery",
        reference: "incident_inc_2048",
        retry_after: "Next update in 15 minutes"
      ),
      SystemStatus.new(
        state: "long",
        code: "500",
        title: "International Research, Production, Reliability Engineering, and Customer Operations could not be loaded",
        description: "The application recorded the failure and preserved the submitted request for delegated administrators across every European production region.",
        variant: :error,
        icon: :circle_x,
        primary_action: "Retry loading the complete organization workspace",
        primary_href: "#retry-long-request",
        secondary_action: "Contact international operations support",
        secondary_href: "#international-support",
        reference: "server_error_international_operations_2048",
        retry_after: nil
      ),
      SystemStatus.new(
        state: "mobile",
        code: "404",
        title: "Page not found",
        description: "Check the address or return home.",
        variant: :default,
        icon: :search_x,
        primary_action: "Go home",
        primary_href: "/gallery",
        secondary_action: nil,
        secondary_href: nil,
        reference: "route_not_found_mobile",
        retry_after: nil
      )
    ].index_by(&:state).freeze

    CHECKOUT_OUTCOMES = [
      CheckoutOutcome.new(
        state: "invoice-issued",
        title: "Invoice issued",
        description: "Enterprise access is scheduled after invoice INV-3049 is paid under the approved net-30 agreement.",
        variant: :success,
        icon: :circle_check,
        reference: "INV-3049",
        amount: "$4,900.00 due August 12, 2026",
        next_step: "Accounts payable receives the immutable invoice PDF by email.",
        action: "View invoice",
        href: "#invoice-inv-3049"
      ),
      CheckoutOutcome.new(
        state: "bank-transfer-pending",
        title: "Bank transfer pending",
        description: "The order is recorded, but access remains pending until the transfer is reconciled.",
        variant: :warning,
        icon: :clock_alert,
        reference: "BTR-2048",
        amount: "€1,290.00 awaiting settlement",
        next_step: "Use reference BTR-2048 when sending the transfer.",
        action: "View transfer instructions",
        href: "#bank-transfer"
      ),
      CheckoutOutcome.new(
        state: "trial-started",
        title: "Your 14-day trial has started",
        description: "Team features are active now. No payment method was charged.",
        variant: :success,
        icon: :circle_check,
        reference: "TRL-2048",
        amount: "$0.00 today",
        next_step: "The trial ends July 27, 2026 unless the workspace selects a paid plan.",
        action: "Open trial workspace",
        href: "#trial-workspace"
      ),
      CheckoutOutcome.new(
        state: "credit-applied",
        title: "Account credit covered this order",
        description: "Available account credit paid the complete renewal balance without charging the saved card.",
        variant: :success,
        icon: :circle_check,
        reference: "CRD-2048",
        amount: "$49.00 credit applied · $0.00 charged",
        next_step: "$18.00 in account credit remains for the next invoice.",
        action: "View credit ledger",
        href: "#credit-ledger"
      ),
      CheckoutOutcome.new(
        state: "manual-review",
        title: "Order is under manual review",
        description: "The order was saved without activating access while the application verifies tax and organization details.",
        variant: :warning,
        icon: :triangle_alert,
        reference: "REV-2048",
        amount: "$12,900.00 authorized · not captured",
        next_step: "Billing operations will respond within one business day.",
        action: "View review details",
        href: "#manual-review"
      ),
      CheckoutOutcome.new(
        state: "long",
        title: "Invoice issued for International Research, Production, Reliability Engineering, and Regulatory Operations",
        description: "Enterprise access activates after the approved procurement organization pays the invoice under its negotiated multi-region services agreement.",
        variant: :success,
        icon: :circle_check,
        reference: "INV-INTERNATIONAL-RESEARCH-3049",
        amount: "DKK 184,927.50 due August 12, 2026",
        next_step: "Accounts-payable+international-research-and-production@example.test receives the signed invoice and tax documentation.",
        action: "Review complete invoice and procurement details",
        href: "#long-invoice"
      ),
      CheckoutOutcome.new(
        state: "mobile",
        title: "Transfer pending",
        description: "Access starts after settlement.",
        variant: :warning,
        icon: :clock_alert,
        reference: "BTR-2048",
        amount: "€1,290.00 pending",
        next_step: "Use BTR-2048 as the transfer reference.",
        action: "Transfer instructions",
        href: "#bank-transfer"
      )
    ].index_by(&:state).freeze

    module_function

    def plans = PLANS
    def features = FEATURES
    def proof = PROOF
    def system_status(state) = SYSTEM_STATUSES.fetch(state)
    def checkout_outcome(state) = CHECKOUT_OUTCOMES.fetch(state)
  end
end
