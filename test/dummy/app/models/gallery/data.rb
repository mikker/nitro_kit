module Gallery
  module Data
    Member = ::Data.define(:id, :name, :email, :role, :status, :avatar_url, :joined_on)
    Activity = ::Data.define(:id, :actor, :action, :subject, :occurred_at)
    Invoice = ::Data.define(:id, :number, :status, :amount_cents, :currency, :issued_on, :due_on)
    Plan = ::Data.define(:id, :name, :price_cents, :interval, :features, :current)
    ApiKey = ::Data.define(:id, :name, :prefix, :access, :last_used_at, :created_at)
    Integration = ::Data.define(:id, :name, :status, :description, :connected_at)
    AuditEvent = ::Data.define(:id, :action, :actor, :ip_address, :occurred_at)
    ButtonExample = ::Data.define(:slug, :label, :variant, :size, :icon, :disabled)
    IconExample = ::Data.define(:slug, :name, :size, :label, :stroke_width)
    AlertExample = ::Data.define(:slug, :title, :description, :variant, :icon)
    AvatarExample = ::Data.define(:slug, :label, :src, :alt, :fallback, :size)
    AvatarStackExample = ::Data.define(:slug, :label, :size, :overflow)
    BadgeExample = ::Data.define(:slug, :label, :variant, :size, :color)
    PaginationExample = ::Data.define(
      :slug,
      :label,
      :current_page,
      :pages,
      :previous_href,
      :next_href
    )
    InputExample = ::Data.define(
      :slug,
      :label,
      :type,
      :value,
      :placeholder,
      :disabled,
      :readonly,
      :required
    )
    AuthIdentity = ::Data.define(:name, :email, :workspace, :inviter, :invited_role, :invited_at)
    OnboardingStep = ::Data.define(:slug, :position, :title, :description)
    ApiKeyReveal = ::Data.define(:key_id, :secret, :revealed_at, :expires_at)
    ApiKeyIssue = ::Data.define(:key, :status, :occurred_at, :message)

    MEMBERS = [
      Member.new(
        id: "mem_ada",
        name: "Ada Lovelace",
        email: "ada@example.test",
        role: :owner,
        status: :active,
        avatar_url: "/gallery/avatars/ada.svg",
        joined_on: Date.new(2024, 2, 12)
      ),
      Member.new(
        id: "mem_grace",
        name: "Grace Hopper",
        email: "grace@example.test",
        role: :admin,
        status: :active,
        avatar_url: "/gallery/avatars/grace.svg",
        joined_on: Date.new(2024, 9, 3)
      ),
      Member.new(
        id: "mem_katherine",
        name: "Katherine Johnson",
        email: "katherine@example.test",
        role: :member,
        status: :invited,
        avatar_url: nil,
        joined_on: nil
      )
    ].freeze

    ACTIVITIES = [
      Activity.new(
        id: "act_deploy",
        actor: MEMBERS.fetch(1),
        action: :deployed,
        subject: "Billing portal",
        occurred_at: Time.utc(2026, 7, 13, 8, 42)
      ),
      Activity.new(
        id: "act_invite",
        actor: MEMBERS.fetch(0),
        action: :invited,
        subject: "Katherine Johnson",
        occurred_at: Time.utc(2026, 7, 12, 16, 18)
      ),
      Activity.new(
        id: "act_key",
        actor: MEMBERS.fetch(0),
        action: :created,
        subject: "Production API key",
        occurred_at: Time.utc(2026, 7, 11, 10, 5)
      )
    ].freeze

    INVOICES = [
      Invoice.new(
        id: "inv_july_2026",
        number: "NK-2026-0713",
        status: :paid,
        amount_cents: 4_900,
        currency: "USD",
        issued_on: Date.new(2026, 7, 1),
        due_on: Date.new(2026, 7, 15)
      ),
      Invoice.new(
        id: "inv_june_2026",
        number: "NK-2026-0612",
        status: :paid,
        amount_cents: 4_900,
        currency: "USD",
        issued_on: Date.new(2026, 6, 1),
        due_on: Date.new(2026, 6, 15)
      ),
      Invoice.new(
        id: "inv_may_2026",
        number: "NK-2026-0511",
        status: :refunded,
        amount_cents: 4_900,
        currency: "USD",
        issued_on: Date.new(2026, 5, 1),
        due_on: Date.new(2026, 5, 15)
      )
    ].freeze

    PLANS = [
      Plan.new(
        id: "plan_starter",
        name: "Starter",
        price_cents: 0,
        interval: :month,
        features: [ "One workspace", "Three members", "Community support" ].freeze,
        current: false
      ),
      Plan.new(
        id: "plan_team",
        name: "Team",
        price_cents: 4_900,
        interval: :month,
        features: [ "Unlimited workspaces", "Twenty members", "Email support" ].freeze,
        current: true
      ),
      Plan.new(
        id: "plan_business",
        name: "Business",
        price_cents: 12_900,
        interval: :month,
        features: [ "Unlimited members", "Audit log", "Priority support" ].freeze,
        current: false
      )
    ].freeze

    API_KEYS = [
      ApiKey.new(
        id: "key_production",
        name: "Production",
        prefix: "nk_live_7P3F",
        access: :read_write,
        last_used_at: Time.utc(2026, 7, 13, 8, 31),
        created_at: Time.utc(2026, 3, 4, 12, 15)
      ),
      ApiKey.new(
        id: "key_reporting",
        name: "Reporting",
        prefix: "nk_live_2M8Q",
        access: :read_only,
        last_used_at: nil,
        created_at: Time.utc(2026, 6, 21, 9, 0)
      )
    ].freeze

    INTEGRATIONS = [
      Integration.new(
        id: "int_github",
        name: "GitHub",
        status: :connected,
        description: "Sync pull requests and deployment activity.",
        connected_at: Time.utc(2026, 2, 14, 15, 20)
      ),
      Integration.new(
        id: "int_slack",
        name: "Slack",
        status: :action_required,
        description: "Post alerts to the team operations channel.",
        connected_at: Time.utc(2026, 4, 18, 11, 45)
      ),
      Integration.new(
        id: "int_sentry",
        name: "Sentry",
        status: :available,
        description: "Link errors to deploys and releases.",
        connected_at: nil
      )
    ].freeze

    AUDIT_EVENTS = [
      AuditEvent.new(
        id: "audit_role",
        action: "Changed Grace Hopper's role from member to admin",
        actor: MEMBERS.fetch(0),
        ip_address: "192.0.2.42",
        occurred_at: Time.utc(2026, 7, 10, 14, 3)
      ),
      AuditEvent.new(
        id: "audit_login",
        action: "Signed in with a recovery code",
        actor: MEMBERS.fetch(1),
        ip_address: "198.51.100.17",
        occurred_at: Time.utc(2026, 7, 9, 7, 52)
      ),
      AuditEvent.new(
        id: "audit_export",
        action: "Exported the workspace audit log",
        actor: MEMBERS.fetch(0),
        ip_address: "192.0.2.42",
        occurred_at: Time.utc(2026, 7, 8, 18, 26)
      )
    ].freeze

    BUTTON_VARIANTS = [
      ButtonExample.new(
        slug: "default",
        label: "Default",
        variant: :default,
        size: :md,
        icon: nil,
        disabled: false
      ),
      ButtonExample.new(
        slug: "primary",
        label: "Primary",
        variant: :primary,
        size: :md,
        icon: :save,
        disabled: false
      ),
      ButtonExample.new(
        slug: "destructive",
        label: "Destructive",
        variant: :destructive,
        size: :md,
        icon: :trash_2,
        disabled: false
      ),
      ButtonExample.new(
        slug: "ghost",
        label: "Ghost",
        variant: :ghost,
        size: :md,
        icon: nil,
        disabled: false
      )
    ].freeze

    BUTTON_SIZES = [
      ButtonExample.new(slug: "xs", label: "Extra small", variant: :default, size: :xs, icon: nil, disabled: false),
      ButtonExample.new(slug: "sm", label: "Small", variant: :default, size: :sm, icon: nil, disabled: false),
      ButtonExample.new(slug: "md", label: "Medium", variant: :default, size: :md, icon: nil, disabled: false),
      ButtonExample.new(slug: "lg", label: "Large", variant: :default, size: :lg, icon: nil, disabled: false),
      ButtonExample.new(slug: "xl", label: "Extra large", variant: :default, size: :xl, icon: nil, disabled: false)
    ].freeze

    ICON_SIZES = [
      IconExample.new(slug: "xs", name: :save, size: :xs, label: "Extra small save icon", stroke_width: 1.5),
      IconExample.new(slug: "sm", name: :save, size: :sm, label: "Small save icon", stroke_width: 1.5),
      IconExample.new(slug: "md", name: :save, size: :md, label: "Medium save icon", stroke_width: 1.5),
      IconExample.new(slug: "lg", name: :save, size: :lg, label: "Large save icon", stroke_width: 1.5),
      IconExample.new(slug: "xl", name: :save, size: :xl, label: "Extra large save icon", stroke_width: 1.5)
    ].freeze

    ALERT_VARIANTS = [
      AlertExample.new(
        slug: "default",
        title: "Workspace updated",
        description: "Your changes are visible to all members.",
        variant: :default,
        icon: :info
      ),
      AlertExample.new(
        slug: "info",
        title: "Release 2026.08 is scheduled",
        description: "Maintenance starts Thursday at 02:00 UTC and lasts about ten minutes.",
        variant: :info,
        icon: :info
      ),
      AlertExample.new(
        slug: "success",
        title: "Invitation sent",
        description: "Katherine Johnson can now join the workspace.",
        variant: :success,
        icon: :circle_check
      ),
      AlertExample.new(
        slug: "warning",
        title: "Payment method expires soon",
        description: "Replace the card ending in 4242 before August 1.",
        variant: :warning,
        icon: :triangle_alert
      ),
      AlertExample.new(
        slug: "error",
        title: "Deployment failed",
        description: "The production release stopped during database migration.",
        variant: :error,
        icon: :circle_x
      )
    ].freeze

    AVATAR_SIZES = [
      AvatarExample.new(
        slug: "sm",
        label: "Small",
        src: nil,
        alt: "Ada Lovelace",
        fallback: "AL",
        size: :sm
      ),
      AvatarExample.new(
        slug: "md",
        label: "Medium",
        src: nil,
        alt: "Grace Hopper",
        fallback: "GH",
        size: :md
      ),
      AvatarExample.new(
        slug: "lg",
        label: "Large",
        src: nil,
        alt: "Katherine Johnson",
        fallback: "KJ",
        size: :lg
      )
    ].freeze

    AVATAR_STACK_SIZES = [
      AvatarStackExample.new(slug: "sm", label: "Small stack", size: :sm, overflow: 2),
      AvatarStackExample.new(slug: "md", label: "Medium stack", size: :md, overflow: 5),
      AvatarStackExample.new(slug: "lg", label: "Large stack", size: :lg, overflow: 12)
    ].freeze

    BADGE_COLORS = NitroKit::Badge::COLORS.map do |color|
      BadgeExample.new(
        slug: color.to_s,
        label: color.to_s.humanize,
        variant: :default,
        size: :md,
        color:
      )
    end.freeze

    BADGE_VARIANTS = [
      BadgeExample.new(slug: "default", label: "Default", variant: :default, size: :md, color: :info),
      BadgeExample.new(slug: "outline", label: "Outline", variant: :outline, size: :md, color: :info)
    ].freeze

    BADGE_SIZES = [
      BadgeExample.new(slug: "sm", label: "Small", variant: :default, size: :sm, color: :neutral),
      BadgeExample.new(slug: "md", label: "Medium", variant: :default, size: :md, color: :neutral)
    ].freeze

    PAGINATION_BOUNDARIES = [
      PaginationExample.new(
        slug: "first",
        label: "First page",
        current_page: 1,
        pages: [ 1, 2, 3 ].freeze,
        previous_href: nil,
        next_href: "/gallery/search?page=2"
      ),
      PaginationExample.new(
        slug: "middle",
        label: "Middle page",
        current_page: 6,
        pages: [ 4, 5, 6, 7, 8 ].freeze,
        previous_href: "/gallery/search?page=5",
        next_href: "/gallery/search?page=7"
      ),
      PaginationExample.new(
        slug: "last",
        label: "Last page",
        current_page: 12,
        pages: [ 10, 11, 12 ].freeze,
        previous_href: "/gallery/search?page=11",
        next_href: nil
      )
    ].freeze

    INPUT_EXAMPLES = [
      InputExample.new(
        slug: "text",
        label: "Workspace name",
        type: :text,
        value: "Mothership",
        placeholder: nil,
        disabled: false,
        readonly: false,
        required: true
      ),
      InputExample.new(
        slug: "email",
        label: "Account email",
        type: :email,
        value: "ada@example.test",
        placeholder: "name@example.test",
        disabled: false,
        readonly: false,
        required: true
      ),
      InputExample.new(
        slug: "password",
        label: "Password",
        type: :password,
        value: "correct horse battery staple",
        placeholder: nil,
        disabled: false,
        readonly: false,
        required: true
      ),
      InputExample.new(
        slug: "search",
        label: "Search members",
        type: :search,
        value: nil,
        placeholder: "Search by name or email",
        disabled: false,
        readonly: false,
        required: false
      ),
      InputExample.new(
        slug: "number",
        label: "Seat limit",
        type: :number,
        value: 20,
        placeholder: nil,
        disabled: false,
        readonly: true,
        required: false
      ),
      InputExample.new(
        slug: "date",
        label: "Renewal date",
        type: :date,
        value: "2026-08-01",
        placeholder: nil,
        disabled: false,
        readonly: false,
        required: false
      ),
      InputExample.new(
        slug: "url",
        label: "Webhook URL",
        type: :url,
        value: "https://example.test/hooks/nitro",
        placeholder: "https://",
        disabled: false,
        readonly: false,
        required: false
      ),
      InputExample.new(
        slug: "disabled",
        label: "Legacy account ID",
        type: :text,
        value: "acct_legacy_42",
        placeholder: nil,
        disabled: true,
        readonly: false,
        required: false
      )
    ].freeze

    AUTH_IDENTITY = AuthIdentity.new(
      name: "Katherine Johnson",
      email: "katherine.johnson+analytical-engines@example.test",
      workspace: "Analytical Engines — Research and Production",
      inviter: "Ada Lovelace",
      invited_role: "Administrator",
      invited_at: Time.utc(2026, 7, 12, 16, 18)
    ).freeze

    ONBOARDING_STEPS = [
      OnboardingStep.new(
        slug: "workspace",
        position: 1,
        title: "Name your workspace",
        description: "Choose the name teammates will see in navigation and security notices."
      ),
      OnboardingStep.new(
        slug: "team",
        position: 2,
        title: "Invite your team",
        description: "Add collaborators now or continue with just your account."
      ),
      OnboardingStep.new(
        slug: "integrations",
        position: 3,
        title: "Connect your tools",
        description: "Start with one integration; every connection can be changed later."
      ),
      OnboardingStep.new(
        slug: "review",
        position: 4,
        title: "Review your setup",
        description: "Confirm the workspace, team, and first integration before creating it."
      )
    ].freeze

    DENSE_MEMBERS = (MEMBERS + [
      Member.new(
        id: "mem_dorothy",
        name: "Dorothy Vaughan",
        email: "dorothy.vaughan@example.test",
        role: :admin,
        status: :active,
        avatar_url: nil,
        joined_on: Date.new(2025, 1, 14)
      ),
      Member.new(
        id: "mem_mary",
        name: "Mary Jackson",
        email: "mary.jackson@example.test",
        role: :member,
        status: :active,
        avatar_url: nil,
        joined_on: Date.new(2025, 3, 21)
      ),
      Member.new(
        id: "mem_annie",
        name: "Annie Easley",
        email: "annie.easley@example.test",
        role: :viewer,
        status: :active,
        avatar_url: nil,
        joined_on: Date.new(2025, 5, 9)
      ),
      Member.new(
        id: "mem_margaret",
        name: "Margaret Hamilton",
        email: "margaret.hamilton@example.test",
        role: :member,
        status: :active,
        avatar_url: nil,
        joined_on: Date.new(2025, 8, 17)
      ),
      Member.new(
        id: "mem_hedy",
        name: "Hedy Lamarr",
        email: "hedy.lamarr@example.test",
        role: :viewer,
        status: :suspended,
        avatar_url: nil,
        joined_on: Date.new(2025, 11, 2)
      ),
      Member.new(
        id: "mem_radia",
        name: "Radia Perlman",
        email: "radia.perlman@example.test",
        role: :member,
        status: :active,
        avatar_url: nil,
        joined_on: Date.new(2026, 1, 19)
      )
    ]).freeze

    DENSE_API_KEYS = (API_KEYS + [
      ApiKey.new(
        id: "key_audit_export",
        name: "Quarterly audit export",
        prefix: "nk_live_9A4D",
        access: :read_only,
        last_used_at: Time.utc(2026, 7, 12, 22, 4),
        created_at: Time.utc(2026, 1, 10, 10, 0)
      ),
      ApiKey.new(
        id: "key_deployment_eu",
        name: "European production deployments",
        prefix: "nk_live_4Q8L",
        access: :read_write,
        last_used_at: Time.utc(2026, 7, 13, 8, 29),
        created_at: Time.utc(2026, 2, 18, 13, 40)
      ),
      ApiKey.new(
        id: "key_incident_response",
        name: "Incident response automation",
        prefix: "nk_live_6C2N",
        access: :read_write,
        last_used_at: Time.utc(2026, 7, 11, 3, 12),
        created_at: Time.utc(2026, 4, 7, 16, 5)
      ),
      ApiKey.new(
        id: "key_finance_reconciliation",
        name: "Finance reconciliation and revenue recognition export",
        prefix: "nk_live_1V7K",
        access: :read_only,
        last_used_at: nil,
        created_at: Time.utc(2026, 5, 29, 8, 0)
      )
    ]).freeze

    API_KEY_REVEAL = ApiKeyReveal.new(
      key_id: "key_reporting",
      secret: "nk_live_2M8Q_7uT9cK4dP6xR3vN8mL1sH5jF",
      revealed_at: Time.utc(2026, 7, 13, 9, 18),
      expires_at: Time.utc(2026, 10, 11, 9, 18)
    ).freeze

    EXPIRED_API_KEY_ISSUE = ApiKeyIssue.new(
      key: API_KEYS.fetch(1),
      status: :expired,
      occurred_at: Time.utc(2026, 7, 1, 0, 0),
      message: "This reporting credential expired before it was installed in the scheduled export job."
    ).freeze

    FAILED_API_KEY_ISSUE = ApiKeyIssue.new(
      key: API_KEYS.fetch(0),
      status: :error,
      occurred_at: Time.utc(2026, 7, 13, 8, 33),
      message: "Revocation could not complete because the audit event store was temporarily unavailable."
    ).freeze

    module_function

    def members = MEMBERS
    def activities = ACTIVITIES
    def invoices = INVOICES
    def plans = PLANS
    def api_keys = API_KEYS
    def integrations = INTEGRATIONS
    def audit_events = AUDIT_EVENTS
    def button_variants = BUTTON_VARIANTS
    def button_sizes = BUTTON_SIZES
    def icon_sizes = ICON_SIZES
    def alert_variants = ALERT_VARIANTS
    def avatar_sizes = AVATAR_SIZES
    def avatar_stack_sizes = AVATAR_STACK_SIZES
    def badge_colors = BADGE_COLORS
    def badge_variants = BADGE_VARIANTS
    def badge_sizes = BADGE_SIZES
    def pagination_boundaries = PAGINATION_BOUNDARIES
    def input_examples = INPUT_EXAMPLES
    def auth_identity = AUTH_IDENTITY
    def onboarding_steps = ONBOARDING_STEPS
    def dense_members = DENSE_MEMBERS
    def dense_api_keys = DENSE_API_KEYS
    def api_key_reveal = API_KEY_REVEAL
    def expired_api_key_issue = EXPIRED_API_KEY_ISSUE
    def failed_api_key_issue = FAILED_API_KEY_ISSUE
  end
end
