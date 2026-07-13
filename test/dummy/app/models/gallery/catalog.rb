module Gallery
  module Catalog
    KINDS = %i[home component block flow].freeze

    Entry = ::Data.define(:kind, :slug, :title, :group, :description, :page, :states, :expected_roots)
    NavigationGroup = ::Data.define(:kind, :title, :description, :entries)

    class EntryNotFound < KeyError
    end

    class StateNotFound < KeyError
    end

    ENTRIES = [
      Entry.new(
        kind: :home,
        slug: "home",
        title: "Overview",
        group: "Gallery",
        description: "The Nitro Kit 2.0 component and application gallery.",
        page: Gallery::Home,
        states: [],
        expected_roots: []
      ),
      Entry.new(
        kind: :component,
        slug: "button",
        title: "Button",
        group: "Actions",
        description: "Native buttons and links with typed variants, sizes, and icons.",
        page: Gallery::Components::ButtonPage,
        states: [],
        expected_roots: %w[button]
      ),
      Entry.new(
        kind: :component,
        slug: "icon",
        title: "Icon",
        group: "Display",
        description: "Lucide icons with decorative and labelled semantics.",
        page: Gallery::Components::IconPage,
        states: [],
        expected_roots: %w[icon]
      ),
      Entry.new(
        kind: :component,
        slug: "button-group",
        title: "Button group",
        group: "Actions",
        description: "One labelled action group containing typed Button children.",
        page: Gallery::Components::ButtonGroupPage,
        states: [],
        expected_roots: %w[button-group button card badge table]
      ),
      Entry.new(
        kind: :component,
        slug: "pagination",
        title: "Pagination",
        group: "Navigation",
        description: "Accessible page navigation with explicit boundaries, current state, and ellipses.",
        page: Gallery::Components::PaginationPage,
        states: [],
        expected_roots: %w[pagination button field input table badge]
      ),
      Entry.new(
        kind: :component,
        slug: "card",
        title: "Card",
        group: "Structure",
        description: "A compound surface with typed title, body, divider, and footer slots.",
        page: Gallery::Components::CardPage,
        states: [],
        expected_roots: %w[card field input badge button-group button]
      ),
      Entry.new(
        kind: :component,
        slug: "input",
        title: "Input",
        group: "Forms",
        description: "Native input controls with explicit HTML semantics.",
        page: Gallery::Components::InputPage,
        states: [],
        expected_roots: %w[input]
      ),
      Entry.new(
        kind: :component,
        slug: "field",
        title: "Field",
        group: "Forms",
        description: "Labels, descriptions, controls, and validation errors as one accessible unit.",
        page: Gallery::Components::FieldPage,
        states: [],
        expected_roots: %w[field input]
      ),
      Entry.new(
        kind: :component,
        slug: "label",
        title: "Label",
        group: "Forms",
        description: "Native labels with explicit control relationships and direct Phlex content.",
        page: Gallery::Components::LabelPage,
        states: [],
        expected_roots: %w[label input textarea select field]
      ),
      Entry.new(
        kind: :component,
        slug: "textarea",
        title: "Textarea",
        group: "Forms",
        description: "Multiline text controls with native values, constraints, and availability state.",
        page: Gallery::Components::TextareaPage,
        states: [],
        expected_roots: %w[textarea field label button]
      ),
      Entry.new(
        kind: :component,
        slug: "select",
        title: "Select",
        group: "Forms",
        description: "Native selection controls with typed choices, prompts, blanks, and multiple values.",
        page: Gallery::Components::SelectPage,
        states: [],
        expected_roots: %w[select field label button]
      ),
      Entry.new(
        kind: :component,
        slug: "checkbox",
        title: "Checkbox",
        group: "Forms",
        description: "Submittable boolean controls with explicit checked, unchecked, and mixed state.",
        page: Gallery::Components::CheckboxPage,
        states: [],
        expected_roots: %w[checkbox input field button]
      ),
      Entry.new(
        kind: :component,
        slug: "checkbox-group",
        title: "Checkbox group",
        group: "Forms",
        description: "A native fieldset of typed multi-select choices with Rails array naming.",
        page: Gallery::Components::CheckboxGroupPage,
        states: [],
        expected_roots: %w[checkbox-group checkbox input button]
      ),
      Entry.new(
        kind: :component,
        slug: "radio-button",
        title: "Radio button",
        group: "Forms",
        description: "Same-name native radio choices with explicit labels, values, sizes, and state.",
        page: Gallery::Components::RadioButtonPage,
        states: [],
        expected_roots: %w[radio-button input field]
      ),
      Entry.new(
        kind: :component,
        slug: "radio-button-group",
        title: "Radio button group",
        group: "Forms",
        description: "A native single-select fieldset with typed choices and required selection semantics.",
        page: Gallery::Components::RadioButtonGroupPage,
        states: [],
        expected_roots: %w[radio-button-group radio-button input field button]
      ),
      Entry.new(
        kind: :component,
        slug: "switch",
        title: "Switch",
        group: "Forms",
        description: "Checkbox-backed settings switches with labels, descriptions, sizes, and submitted values.",
        page: Gallery::Components::SwitchPage,
        states: [],
        expected_roots: %w[switch input field button]
      ),
      Entry.new(
        kind: :component,
        slug: "field-group",
        title: "Field group",
        group: "Forms",
        description: "A layout boundary for related direct or FormBuilder-backed fields.",
        page: Gallery::Components::FieldGroupPage,
        states: [],
        expected_roots: %w[field-group field input textarea select checkbox switch button]
      ),
      Entry.new(
        kind: :component,
        slug: "fieldset",
        title: "Fieldset",
        group: "Forms",
        description: "A semantic form section with legend, guidance, grouped fields, and disabled state.",
        page: Gallery::Components::FieldsetPage,
        states: [],
        expected_roots: %w[fieldset field-group field input select checkbox button]
      ),
      Entry.new(
        kind: :component,
        slug: "table",
        title: "Table",
        group: "Structure",
        description: "Semantic tabular data with typed alignment and scope.",
        page: Gallery::Components::TablePage,
        states: [],
        expected_roots: %w[table badge button-group button]
      ),
      Entry.new(
        kind: :component,
        slug: "dialog",
        title: "Dialog",
        group: "Overlays",
        description: "A native dialog with Nitro-owned trigger, state, and accessible relationships.",
        page: Gallery::Components::DialogPage,
        states: [],
        expected_roots: %w[dialog button field input]
      ),
      Entry.new(
        kind: :component,
        slug: "dropdown",
        title: "Dropdown",
        group: "Overlays",
        description: "Native popover menus with typed triggers, entries, placement, and keyboard state.",
        page: Gallery::Components::DropdownPage,
        states: [],
        expected_roots: %w[dropdown card badge]
      ),
      Entry.new(
        kind: :component,
        slug: "tooltip",
        title: "Tooltip",
        group: "Overlays",
        description: "Contextual descriptions attached to an owned, focusable Button trigger.",
        page: Gallery::Components::TooltipPage,
        states: [],
        expected_roots: %w[tooltip card badge button]
      ),
      Entry.new(
        kind: :component,
        slug: "combobox",
        title: "Combobox",
        group: "Forms",
        description: "Searchable typed choices with distinct display labels and submitted values.",
        page: Gallery::Components::ComboboxPage,
        states: [],
        expected_roots: %w[combobox field input card button]
      ),
      Entry.new(
        kind: :component,
        slug: "datepicker",
        title: "Datepicker",
        group: "Forms",
        description: "A native date control with explicit constraints and server-owned semantics.",
        page: Gallery::Components::DatepickerPage,
        states: [],
        expected_roots: %w[datepicker field card button]
      ),
      Entry.new(
        kind: :component,
        slug: "toast",
        title: "Toast",
        group: "Overlays",
        description: "Explicit notification markup, Rails flash mapping, and pauseable dismissal behavior.",
        page: Gallery::Components::ToastPage,
        states: [],
        expected_roots: %w[toast badge card button]
      ),
      Entry.new(
        kind: :component,
        slug: "alert",
        title: "Alert",
        group: "Display",
        description: "Status messages with typed intent, title, description, and icon slots.",
        page: Gallery::Components::AlertPage,
        states: [],
        expected_roots: %w[alert icon card badge avatar-stack avatar]
      ),
      Entry.new(
        kind: :component,
        slug: "avatar",
        title: "Avatar",
        group: "Display",
        description: "Images and accessible initial fallbacks at predictable sizes.",
        page: Gallery::Components::AvatarPage,
        states: [],
        expected_roots: %w[avatar]
      ),
      Entry.new(
        kind: :component,
        slug: "avatar-stack",
        title: "Avatar stack",
        group: "Display",
        description: "A labelled group of consistently sized avatars with overflow state.",
        page: Gallery::Components::AvatarStackPage,
        states: [],
        expected_roots: %w[avatar-stack avatar]
      ),
      Entry.new(
        kind: :component,
        slug: "badge",
        title: "Badge",
        group: "Display",
        description: "Compact status labels with typed color, variant, and size.",
        page: Gallery::Components::BadgePage,
        states: [],
        expected_roots: %w[badge icon table avatar]
      ),
      Entry.new(
        kind: :component,
        slug: "accordion",
        title: "Accordion",
        group: "Structure",
        description: "Keyed disclosure sections with native buttons and visible state.",
        page: Gallery::Components::AccordionPage,
        states: [],
        expected_roots: %w[accordion card badge table button-group button]
      ),
      Entry.new(
        kind: :component,
        slug: "tabs",
        title: "Tabs",
        group: "Structure",
        description: "Keyed tab and panel pairs with automatic or manual keyboard activation.",
        page: Gallery::Components::TabsPage,
        states: [],
        expected_roots: %w[tabs card field input table badge button-group button]
      ),
      Entry.new(
        kind: :component,
        slug: "v-stack",
        title: "Vertical stack",
        group: "Layout",
        description: "Token-spaced vertical rhythm with explicit intrinsic, centered, or stretched child alignment.",
        page: Gallery::Components::VStackPage,
        states: [],
        expected_roots: %w[v-stack h-stack grid container card alert badge button]
      ),
      Entry.new(
        kind: :component,
        slug: "h-stack",
        title: "Horizontal stack",
        group: "Layout",
        description: "Token-spaced rows with closed alignment, distribution, and wrapping decisions.",
        page: Gallery::Components::HStackPage,
        states: [],
        expected_roots: %w[h-stack v-stack container card badge button]
      ),
      Entry.new(
        kind: :component,
        slug: "grid",
        title: "Grid",
        group: "Layout",
        description: "The proven three-column collection layout with one Nitro-owned narrow collapse.",
        page: Gallery::Components::GridPage,
        states: [],
        expected_roots: %w[grid v-stack h-stack container card badge button]
      ),
      Entry.new(
        kind: :component,
        slug: "container",
        title: "Container",
        group: "Layout",
        description: "Centered content maximums backed by the existing public width tokens.",
        page: Gallery::Components::ContainerPage,
        states: [],
        expected_roots: %w[container v-stack h-stack grid card alert badge button]
      ),
      Entry.new(
        kind: :block,
        slug: "auth-shell",
        title: "Authentication shell",
        group: "Authentication",
        description: "A semantic narrow page landmark that owns gutters and layout while applications own every visible authentication region.",
        page: Gallery::Blocks::AuthShellPage,
        states: [],
        expected_roots: %w[auth-shell container v-stack card alert field input button]
      ),
      Entry.new(
        kind: :block,
        slug: "settings-layout",
        title: "Settings layout",
        group: "Navigation and progress",
        description: "A labelled settings navigation beside one neutral content region with a Nitro-owned narrow stack.",
        page: Gallery::Blocks::SettingsLayoutPage,
        states: [],
        expected_roots: %w[settings-layout button-group button card field input toolbar pagination-bar pagination v-stack]
      ),
      Entry.new(
        kind: :block,
        slug: "toolbar",
        title: "Toolbar",
        group: "Navigation and progress",
        description: "Neutral leading and trailing regions with owned distribution, wrapping, and narrow stacking.",
        page: Gallery::Blocks::ToolbarPage,
        states: [],
        expected_roots: %w[toolbar badge button-group button card container]
      ),
      Entry.new(
        kind: :block,
        slug: "pagination-bar",
        title: "Pagination bar",
        group: "Navigation and progress",
        description: "Caller-owned result context placed beside exactly one typed Pagination.",
        page: Gallery::Blocks::PaginationBarPage,
        states: [],
        expected_roots: %w[pagination-bar pagination button badge card table]
      ),
      Entry.new(
        kind: :block,
        slug: "page-header",
        title: "Page header",
        group: "Content and forms",
        description: "A fixed page-level heading sequence with optional context and one typed action group.",
        page: Gallery::Blocks::PageHeaderPage,
        states: [],
        expected_roots: %w[page-header button-group button container]
      ),
      Entry.new(
        kind: :block,
        slug: "stat-grid",
        title: "Stat grid",
        group: "Content and forms",
        description: "Keyed label, value, and detail records in the proven three-column responsive grid.",
        page: Gallery::Blocks::StatGridPage,
        states: [],
        expected_roots: %w[stat-grid grid container]
      ),
      Entry.new(
        kind: :block,
        slug: "data-section",
        title: "Data section",
        group: "Content and forms",
        description: "An owned section heading around exactly one caller-populated Table or typed EmptyState.",
        page: Gallery::Blocks::DataSectionPage,
        states: [],
        expected_roots: %w[data-section table badge button-group button empty-state icon container]
      ),
      Entry.new(
        kind: :block,
        slug: "form-section",
        title: "Form section",
        group: "Content and forms",
        description: "A section frame for one complete caller-owned Rails form and an optional typed status.",
        page: Gallery::Blocks::FormSectionPage,
        states: [],
        expected_roots: %w[form-section alert field input switch button container]
      ),
      Entry.new(
        kind: :block,
        slug: "danger-zone",
        title: "Danger zone",
        group: "Content and forms",
        description: "Impact anatomy around a caller-owned confirmation composition and explicit safe escape.",
        page: Gallery::Blocks::DangerZonePage,
        states: [],
        expected_roots: %w[danger-zone button dialog field input container]
      ),
      Entry.new(
        kind: :block,
        slug: "empty-state",
        title: "Empty state",
        group: "Content and forms",
        description: "An explicit empty result with controlled heading hierarchy, icon, and up to two actions.",
        page: Gallery::Blocks::EmptyStatePage,
        states: [],
        expected_roots: %w[empty-state icon button container]
      ),
      Entry.new(
        kind: :flow,
        slug: "sign-in",
        title: "Sign in",
        group: "Authentication",
        description: "AuthShell-composed credential entry, validation, submission, success, and mobile pressure.",
        page: Gallery::Flows::SignInPage,
        states: %w[default invalid loading success mobile],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "password-reset",
        title: "Password reset",
        group: "Authentication",
        description: "AuthShell-composed recovery request, delivery, replacement, expiration, and loading states.",
        page: Gallery::Flows::PasswordResetPage,
        states: %w[request validation sent update expired loading],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "email-verification",
        title: "Email verification",
        group: "Authentication",
        description: "AuthShell-composed pending, verified, expired, invalid-token, and long-copy identity states.",
        page: Gallery::Flows::EmailVerificationPage,
        states: %w[pending verified expired invalid-token long-copy],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "invitation-acceptance",
        title: "Invitation acceptance",
        group: "Authentication",
        description: "AuthShell-composed workspace invitation setup, validation, token recovery, completion, and mobile pressure.",
        page: Gallery::Flows::InvitationAcceptancePage,
        states: %w[valid validation loading accepted expired invalid-token mobile],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "account-creation",
        title: "Account creation",
        group: "Authentication",
        description: "AuthShell-composed registration, consent, validation, submission, verification handoff, and content pressure.",
        page: Gallery::Flows::AccountCreationPage,
        states: %w[default validation loading success long-copy mobile],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "onboarding",
        title: "Workspace onboarding",
        group: "Onboarding",
        description: "AuthShell-composed workspace, team, integration, review, resume, validation, loading, and completion steps.",
        page: Gallery::Flows::OnboardingPage,
        states: %w[workspace workspace-validation team integrations review loading complete resume mobile],
        expected_roots: %w[auth-shell container v-stack card button]
      ),
      Entry.new(
        kind: :flow,
        slug: "dashboard",
        title: "Workspace dashboard",
        group: "Workspace",
        description: "A block-composed dashboard with semantic chart pressure across new, active, degraded, loading, dense, and mobile states.",
        page: Gallery::Flows::DashboardPage,
        states: %w[new active degraded loading dense mobile],
        expected_roots: %w[container v-stack page-header button]
      ),
      Entry.new(
        kind: :flow,
        slug: "settings",
        title: "Workspace settings",
        group: "Workspace",
        description: "Block-composed profile, security, notification, integration, and appearance settings.",
        page: Gallery::Flows::SettingsPage,
        states: %w[
          profile profile-validation profile-success security security-disabled notifications notifications-success
          integrations integrations-empty integrations-error appearance appearance-loading long-content mobile
        ],
        expected_roots: %w[container v-stack settings-layout button]
      ),
      Entry.new(
        kind: :flow,
        slug: "billing",
        title: "Subscription billing",
        group: "Workspace",
        description: "Block-composed plan, payment, paginated invoice, cancellation, outcome, and mobile billing states.",
        page: Gallery::Flows::BillingPage,
        states: %w[
          plans payment-method payment-validation payment-loading payment-updated invoices invoice-detail invoice-empty
          cancellation cancellation-validation cancellation-loading cancelled mobile
        ],
        expected_roots: %w[container v-stack button]
      ),
      Entry.new(
        kind: :flow,
        slug: "users",
        title: "Workspace users",
        group: "Workspace",
        description: "Block-composed paginated user index and search plus detail, empty, loading, error, bulk, outcome, and mobile states.",
        page: Gallery::Flows::UsersPage,
        states: %w[index detail search empty loading error bulk bulk-confirmation bulk-complete mobile],
        expected_roots: %w[container v-stack button]
      ),
      Entry.new(
        kind: :flow,
        slug: "team-management",
        title: "Team management",
        group: "Workspace",
        description: "Block-composed member inventory, invitation, role, removal, outcome, density, and mobile states.",
        page: Gallery::Flows::TeamManagementPage,
        states: %w[
          members search empty invite invite-validation loading role-change remove-confirmation removed error dense mobile
        ],
        expected_roots: %w[container v-stack button]
      ),
      Entry.new(
        kind: :flow,
        slug: "api-credentials",
        title: "API credentials",
        group: "Workspace",
        description: "Block-composed credential inventory, creation, reveal-once, revocation, recovery, density, and mobile states.",
        page: Gallery::Flows::ApiCredentialsPage,
        states: %w[
          list empty create validation loading reveal-once revoke-confirmation revoked expired error long dense mobile
        ],
        expected_roots: %w[container v-stack button]
      ),
      Entry.new(
        kind: :flow,
        slug: "organization-overview",
        title: "Organization overview",
        group: "Organization",
        description: "Block-composed organization identity, capacity, resource inventory, availability, density, and mobile states.",
        page: Gallery::Flows::OrganizationOverviewPage,
        states: %w[active empty error dense long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "organization-settings",
        title: "Organization settings",
        group: "Organization",
        description: "Block-composed identity, access, integration, validation, authorization, long-content, and mobile settings.",
        page: Gallery::Flows::OrganizationSettingsPage,
        states: %w[general access integrations validation success error long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "team-activity",
        title: "Team activity",
        group: "Organization",
        description: "Searchable and filterable organization access activity with empty, failure, density, long-content, and mobile states.",
        page: Gallery::Flows::TeamActivityPage,
        states: %w[recent search filtered empty error dense long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "team-member",
        title: "Team member",
        group: "Organization",
        description: "Member identity, lifecycle, caller-owned authorization, activity, missing, failure, long-content, and mobile states.",
        page: Gallery::Flows::TeamMemberPage,
        states: %w[active invited suspended activity empty error long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "data-resource-overview",
        title: "Data resource overview",
        group: "Data resources",
        description: "Searchable and filterable resource inventory with bulk selection, empty, failure, density, long-content, and mobile states.",
        page: Gallery::Flows::DataResourceOverviewPage,
        states: %w[index search filtered bulk empty error dense long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "data-resource-activity",
        title: "Data resource activity",
        group: "Data resources",
        description: "Resource-scoped operational activity with composed filters, empty, failure, density, long-content, and mobile states.",
        page: Gallery::Flows::DataResourceActivityPage,
        states: %w[recent filtered empty error dense long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "data-resource-settings",
        title: "Data resource settings",
        group: "Data resources",
        description: "Resource configuration, access, validation, authorization, archival, long-content, and mobile settings states.",
        page: Gallery::Flows::DataResourceSettingsPage,
        states: %w[general validation success access danger error long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "checkout",
        title: "Checkout and payment",
        group: "Billing",
        description: "Block-composed order review, payment entry, provider outcomes, cancellation, refunds, and pressure states.",
        page: Gallery::Flows::CheckoutPage,
        states: %w[
          review payment validation processing succeeded failed requires-action cancelled refunded empty-cart long mobile
        ],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "account-security",
        title: "Account security",
        group: "Authentication",
        description: "AuthShell-composed recovery, token expiry, locks, two-factor challenges, recovery codes, trust, and pressure states.",
        page: Gallery::Flows::AccountSecurityPage,
        states: %w[
          recovery-request recovery-validation recovery-sent reset reset-expired account-locked unlock-sent
          two-factor-challenge two-factor-invalid recovery-code recovery-code-invalid trusted-device loading success long mobile
        ],
        expected_roots: %w[auth-shell page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "onboarding-branches",
        title: "Branched onboarding",
        group: "Onboarding",
        description: "Block-composed company, personal, and import branches with explicit skips, reviews, resume, and outcomes.",
        page: Gallery::Flows::OnboardingBranchesPage,
        states: %w[
          choose-path company solo import invite-team skip-team integration skip-integration review-company review-solo
          validation saving complete resume long mobile
        ],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "api-webhooks",
        title: "API webhooks",
        group: "API",
        description: "Block-composed endpoint inventory, configuration, signing secrets, deliveries, failures, retries, and pressure states.",
        page: Gallery::Flows::ApiWebhooksPage,
        states: %w[
          list empty detail create validation loading delivery-succeeded delivery-failed retrying disabled signing-secret
          dense long mobile
        ],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "integration-management",
        title: "Integration management",
        group: "Workspace operations",
        description: "Block-composed provider catalog, detail, connected inventory, configuration recovery, and mobile states.",
        page: Gallery::Flows::IntegrationManagementPage,
        states: %w[catalog detail connected config-error mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "uploads",
        title: "File uploads",
        group: "Workspace operations",
        description: "Rails-native multipart upload forms across empty, uploading, complete, rejected, multiple, long, and mobile states.",
        page: Gallery::Flows::UploadsPage,
        states: %w[empty uploading complete error multiple long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "activity-audit",
        title: "Activity and audit log",
        group: "Workspace operations",
        description: "Searchable workspace audit history across normal, filtered, empty, dense, failure, and mobile states.",
        page: Gallery::Flows::ActivityAuditPage,
        states: %w[normal filter empty dense error mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "changelog",
        title: "Changelog",
        group: "Product",
        description: "Block-composed latest release, archive, empty, long-content, and mobile documentation states.",
        page: Gallery::Flows::ChangelogPage,
        states: %w[latest archive empty long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "help-center",
        title: "Help center",
        group: "Support",
        description: "FAQ, search, zero-result, support contact, validation, outcome, long-content, and mobile states.",
        page: Gallery::Flows::HelpCenterPage,
        states: %w[faq search empty contact contact-validation contact-sent long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "system-status",
        title: "System status and errors",
        group: "System",
        description: "Caller-owned HTTP failures, maintenance, connectivity, rate limits, degradation, and pressure states.",
        page: Gallery::Flows::SystemStatusPage,
        states: %w[403 404 422 500 maintenance offline rate-limited degraded long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "landing",
        title: "Product landing",
        group: "Marketing",
        description: "A direct block-composed public landing page with announcement, proof, long-content, and mobile states.",
        page: Gallery::Flows::LandingPage,
        states: %w[default announcement customer-proof long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "pricing",
        title: "Public pricing",
        group: "Marketing",
        description: "Monthly, annual, comparison, enterprise, long-content, and mobile pricing compositions.",
        page: Gallery::Flows::PricingPage,
        states: %w[monthly annual comparison enterprise long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "features",
        title: "Product features",
        group: "Marketing",
        description: "Overview, security, automation, collaboration, long-content, and mobile feature compositions.",
        page: Gallery::Flows::FeaturesPage,
        states: %w[overview security automation collaboration long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "contact",
        title: "Public contact",
        group: "Marketing",
        description: "A Rails-native public inquiry across validation, submission, result, availability, and pressure states.",
        page: Gallery::Flows::ContactPage,
        states: %w[form validation sending sent unavailable long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      ),
      Entry.new(
        kind: :flow,
        slug: "checkout-result",
        title: "Checkout results",
        group: "Billing",
        description: "Invoice, bank transfer, trial, account credit, manual review, long-content, and mobile outcomes.",
        page: Gallery::Flows::CheckoutResultPage,
        states: %w[invoice-issued bank-transfer-pending trial-started credit-applied manual-review long mobile],
        expected_roots: %w[page-header container v-stack button-group button]
      )
    ].freeze

    GROUPS = [
      NavigationGroup.new(
        kind: :component,
        title: "Components",
        description: "Atoms and their meaningful combinations.",
        entries: ENTRIES.select { |entry| entry.kind == :component }
      ),
      NavigationGroup.new(
        kind: :block,
        title: "Blocks",
        description: "Typed compositions extracted from application flows.",
        entries: ENTRIES.select { |entry| entry.kind == :block }
      ),
      NavigationGroup.new(
        kind: :flow,
        title: "Flows",
        description: "Realistic Rails screens and product states.",
        entries: ENTRIES.select { |entry| entry.kind == :flow }
      )
    ].freeze

    module_function

    def home
      ENTRIES.first
    end

    def entries(kind: nil)
      return ENTRIES unless kind

      ENTRIES.select { |entry| entry.kind == kind.to_sym }
    end

    def navigation_groups
      GROUPS
    end

    def fetch!(kind:, slug:)
      entries(kind:).find { |entry| entry.slug == slug } ||
        raise(EntryNotFound, "Unknown #{kind} gallery entry #{slug.inspect}")
    end

    def resolve_state!(entry, state)
      return if entry.states.empty? && state.blank?

      resolved_state = state.presence || entry.states.first
      return resolved_state if entry.states.include?(resolved_state)

      raise StateNotFound, "Unknown state #{state.inspect} for #{entry.slug.inspect}"
    end

    def path_for(entry, routes:, state: nil)
      case entry.kind
      when :home
        routes.gallery_root_path
      when :component
        routes.gallery_component_path(entry.slug)
      when :block
        routes.gallery_block_path(entry.slug)
      when :flow
        routes.gallery_flow_path(slug: entry.slug, state: state || entry.states.first)
      else
        raise ArgumentError, "Unknown gallery entry kind #{entry.kind.inspect}"
      end
    end
  end
end
