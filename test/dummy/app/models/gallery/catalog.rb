module Gallery
  module Catalog
    KINDS = %i[home component composition].freeze

    # `subcategory` groups components in the sidebar; it is nil for every other
    # kind.
    Entry = ::Data.define(:kind, :subcategory, :slug, :title, :description, :page, :states, :expected_roots) do
      def initialize(subcategory: nil, **) = super
    end
    Category = ::Data.define(:slug, :title, :description, :entries)
    Collection = ::Data.define(:kind, :title, :description, :categories) do
      def entries
        categories.flat_map(&:entries)
      end
    end

    class EntryNotFound < KeyError
    end

    class StateNotFound < KeyError
    end

    class CollectionNotFound < KeyError
    end

    class CategoryNotFound < KeyError
    end

    ENTRIES = [
      Entry.new(
        kind: :home,
        slug: "home",
        title: "Introduction",
        description: "What Nitro Kit is and the rules behind it.",
        page: Gallery::Home,
        states: [],
        expected_roots: []
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "button",
        title: "Button",
        description: "Native buttons and links with typed variants, sizes, and icons.",
        page: Gallery::Components::ButtonPage,
        states: [],
        expected_roots: %w[button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "icon",
        title: "Icon",
        description: "Lucide icons with decorative and labelled semantics.",
        page: Gallery::Components::IconPage,
        states: [],
        expected_roots: %w[icon]
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "button-group",
        title: "Button group",
        description: "One labelled action group containing typed Button children.",
        page: Gallery::Components::ButtonGroupPage,
        states: [],
        expected_roots: %w[button-group button card badge table]
      ),
      Entry.new(
        kind: :component,
        subcategory: :navigation,
        slug: "pagination",
        title: "Pagination",
        description: "Accessible page navigation with explicit boundaries, current state, and ellipses.",
        page: Gallery::Components::PaginationPage,
        states: [],
        expected_roots: %w[pagination button field input table badge]
      ),
      Entry.new(
        kind: :component,
        subcategory: :navigation,
        slug: "app-navigation",
        title: "Application navigation",
        description: "A labelled application destination tree with explicit body anatomy, current state, icons, badges, sections, and flexible spacing.",
        page: Gallery::Components::AppNavigationPage,
        states: [],
        expected_roots: %w[app-navigation icon badge button button-group]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "card",
        title: "Card",
        description: "A compound surface with typed title, body, divider, and footer slots.",
        page: Gallery::Components::CardPage,
        states: [],
        expected_roots: %w[card field input badge button-group button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "input",
        title: "Input",
        description: "Native input controls with explicit HTML semantics.",
        page: Gallery::Components::InputPage,
        states: [],
        expected_roots: %w[input field card button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "field",
        title: "Field",
        description: "Labels, descriptions, controls, and validation errors as one accessible unit.",
        page: Gallery::Components::FieldPage,
        states: [],
        expected_roots: %w[field input]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "label",
        title: "Label",
        description: "Native labels with explicit control relationships and direct Phlex content.",
        page: Gallery::Components::LabelPage,
        states: [],
        expected_roots: %w[label input textarea select field]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "textarea",
        title: "Textarea",
        description: "Multiline text controls with native values, constraints, and availability state.",
        page: Gallery::Components::TextareaPage,
        states: [],
        expected_roots: %w[textarea field label button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "rich-text-area",
        title: "Rich text area",
        description: "Action Text editors wrapped in the Nitro contract, composed through Field(as: :rich_text).",
        page: Gallery::Components::RichTextAreaPage,
        states: [],
        expected_roots: %w[rich-text-area field input label button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "select",
        title: "Select",
        description: "Native selection controls with typed choices, prompts, blanks, and multiple values.",
        page: Gallery::Components::SelectPage,
        states: [],
        expected_roots: %w[select field label button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "checkbox",
        title: "Checkbox",
        description: "Submittable boolean controls with explicit checked, unchecked, and mixed state.",
        page: Gallery::Components::CheckboxPage,
        states: [],
        expected_roots: %w[checkbox input field button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "checkbox-group",
        title: "Checkbox group",
        description: "A native fieldset of typed multi-select choices with Rails array naming.",
        page: Gallery::Components::CheckboxGroupPage,
        states: [],
        expected_roots: %w[checkbox-group checkbox input button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "radio-button",
        title: "Radio button",
        description: "Same-name native radio choices with explicit labels, values, sizes, and state.",
        page: Gallery::Components::RadioButtonPage,
        states: [],
        expected_roots: %w[radio-button input field]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "radio-button-group",
        title: "Radio button group",
        description: "A native single-select fieldset with typed choices and required selection semantics.",
        page: Gallery::Components::RadioButtonGroupPage,
        states: [],
        expected_roots: %w[radio-button-group radio-button input field button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "switch",
        title: "Switch",
        description: "Checkbox-backed settings switches with labels, descriptions, sizes, and submitted values.",
        page: Gallery::Components::SwitchPage,
        states: [],
        expected_roots: %w[switch input field button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "field-group",
        title: "Field group",
        description: "A layout boundary for related direct or FormBuilder-backed fields.",
        page: Gallery::Components::FieldGroupPage,
        states: [],
        expected_roots: %w[field-group field input textarea select checkbox switch button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "fieldset",
        title: "Fieldset",
        description: "A semantic form section with legend, guidance, grouped fields, and disabled state.",
        page: Gallery::Components::FieldsetPage,
        states: [],
        expected_roots: %w[fieldset field-group field input select checkbox button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "appearance-picker",
        title: "Appearance picker",
        description: "Native light, dark, and system preferences synchronized through one document runtime.",
        page: Gallery::Components::AppearancePickerPage,
        states: [],
        expected_roots: %w[appearance-picker card badge]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "table",
        title: "Table",
        description: "Semantic tabular data with typed alignment, scope, and caller-owned sort links.",
        page: Gallery::Components::TablePage,
        states: [],
        expected_roots: %w[table field-group field input select toolbar button badge button-group flex pagination-bar pagination]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "details-table",
        title: "Details table",
        description: "Record attributes with deterministic Rails values and explicit custom rendering.",
        page: Gallery::Components::DetailsTablePage,
        states: [],
        expected_roots: %w[details-table table badge card progressive-image]
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "dialog",
        title: "Dialog",
        description: "A native dialog with Nitro-owned trigger, state, and accessible relationships.",
        page: Gallery::Components::DialogPage,
        states: [],
        expected_roots: %w[dialog button field input]
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "dropdown",
        title: "Dropdown",
        description: "Native popover menus with typed triggers, entries, placement, and keyboard state.",
        page: Gallery::Components::DropdownPage,
        states: [],
        expected_roots: %w[dropdown card badge]
      ),
      Entry.new(
        kind: :component,
        subcategory: :feedback,
        slug: "tooltip",
        title: "Tooltip",
        description: "Contextual descriptions attached to an owned, focusable Button trigger.",
        page: Gallery::Components::TooltipPage,
        states: [],
        expected_roots: %w[tooltip card badge button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "combobox",
        title: "Combobox",
        description: "Searchable typed choices with distinct display labels and submitted values.",
        page: Gallery::Components::ComboboxPage,
        states: [],
        expected_roots: %w[combobox field input card button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "dropzone",
        title: "Dropzone",
        description: "Native file selection and drag-and-drop with optional Active Storage direct uploads.",
        page: Gallery::Components::DropzonePage,
        states: [],
        expected_roots: %w[dropzone button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :feedback,
        slug: "toast",
        title: "Toast",
        description: "Explicit notification markup, Rails flash mapping, and pauseable dismissal behavior.",
        page: Gallery::Components::ToastPage,
        states: [],
        expected_roots: %w[toast badge card button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :feedback,
        slug: "alert",
        title: "Alert",
        description: "Status messages with typed intent, title, description, and icon slots.",
        page: Gallery::Components::AlertPage,
        states: [],
        expected_roots: %w[alert icon card badge avatar-stack avatar]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "avatar",
        title: "Avatar",
        description: "Images and accessible initial fallbacks at predictable sizes.",
        page: Gallery::Components::AvatarPage,
        states: [],
        expected_roots: %w[avatar]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "progressive-image",
        title: "Progressive image",
        description: "Active Storage images with low-resolution previews and explicit lifecycle states.",
        page: Gallery::Components::ProgressiveImagePage,
        states: [],
        expected_roots: %w[progressive-image card details-table table badge]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "avatar-stack",
        title: "Avatar stack",
        description: "A labelled group of consistently sized avatars with overflow state.",
        page: Gallery::Components::AvatarStackPage,
        states: [],
        expected_roots: %w[avatar-stack avatar]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "badge",
        title: "Badge",
        description: "Compact status labels with typed color, variant, and size.",
        page: Gallery::Components::BadgePage,
        states: [],
        expected_roots: %w[badge icon table avatar]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "accordion",
        title: "Accordion",
        description: "Keyed disclosure sections with native buttons and visible state.",
        page: Gallery::Components::AccordionPage,
        states: [],
        expected_roots: %w[accordion card badge table button-group button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :navigation,
        slug: "tabs",
        title: "Tabs",
        description: "Keyed tab and panel pairs with automatic or manual keyboard activation.",
        page: Gallery::Components::TabsPage,
        states: [],
        expected_roots: %w[tabs card field input table badge button-group button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "flex",
        title: "Flex",
        description: "Responsive rows and columns with Tailwind-style breakpoint shorthand and closed layout values.",
        page: Gallery::Components::FlexPage,
        states: [],
        expected_roots: %w[flex container card badge button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "grid",
        title: "Grid",
        description: "Responsive one-to-twelve-column collections with Tailwind-style breakpoint shorthand.",
        page: Gallery::Components::GridPage,
        states: [],
        expected_roots: %w[grid flex container card badge button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "container",
        title: "Container",
        description: "Centered content maximums backed by the existing public width tokens.",
        page: Gallery::Components::ContainerPage,
        states: [],
        expected_roots: %w[container flex grid card alert badge button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "typeset",
        title: "Typeset",
        description: "Theme-aware reading rhythm for semantic HTML and rendered rich content.",
        page: Gallery::Components::TypesetPage,
        states: [],
        expected_roots: %w[typeset container card button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "auth-shell",
        title: "Authentication shell",
        description: "A semantic narrow page landmark that owns gutters and layout while applications own every visible authentication region.",
        page: Gallery::Components::AuthShellPage,
        states: [],
        expected_roots: %w[auth-shell container flex card alert field input button]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "app-shell",
        title: "Application shell",
        description: "Sidebar, topbar, and hybrid application frames that reflow one AppNavigation tree through an accessible narrow drawer.",
        page: Gallery::Components::AppShellPage,
        states: [],
        expected_roots: %w[app-shell app-navigation icon badge button-group button container card]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "settings-layout",
        title: "Settings layout",
        description: "A labelled settings navigation beside one neutral content region with a Nitro-owned narrow stack.",
        page: Gallery::Components::SettingsLayoutPage,
        states: [],
        expected_roots: %w[settings-layout button card field input toolbar pagination-bar pagination flex]
      ),
      Entry.new(
        kind: :component,
        subcategory: :navigation,
        slug: "toolbar",
        title: "Toolbar",
        description: "Neutral leading and trailing regions with owned distribution, wrapping, and narrow stacking.",
        page: Gallery::Components::ToolbarPage,
        states: [],
        expected_roots: %w[toolbar badge button-group button card container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :navigation,
        slug: "pagination-bar",
        title: "Pagination bar",
        description: "Caller-owned result context placed beside exactly one typed Pagination.",
        page: Gallery::Components::PaginationBarPage,
        states: [],
        expected_roots: %w[pagination-bar pagination button badge card table]
      ),
      Entry.new(
        kind: :component,
        subcategory: :layout,
        slug: "page-header",
        title: "Page header",
        description: "A fixed page-level heading sequence with optional context and one typed action group.",
        page: Gallery::Components::PageHeaderPage,
        states: [],
        expected_roots: %w[page-header button-group button container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "stat-grid",
        title: "Stat grid",
        description: "Keyed label, value, and detail records in a responsive one-to-three-column grid.",
        page: Gallery::Components::StatGridPage,
        states: [],
        expected_roots: %w[stat-grid grid container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :data,
        slug: "data-section",
        title: "Data section",
        description: "An owned section heading around exactly one caller-populated Table or typed EmptyState.",
        page: Gallery::Components::DataSectionPage,
        states: [],
        expected_roots: %w[data-section table badge button-group button empty-state icon container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :forms,
        slug: "form-section",
        title: "Form section",
        description: "A section frame for one complete caller-owned Rails form and an optional typed status.",
        page: Gallery::Components::FormSectionPage,
        states: [],
        expected_roots: %w[form-section alert field input switch button container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :actions,
        slug: "danger-zone",
        title: "Danger zone",
        description: "Impact anatomy around a caller-owned confirmation composition and explicit safe escape.",
        page: Gallery::Components::DangerZonePage,
        states: [],
        expected_roots: %w[danger-zone button dialog field input container]
      ),
      Entry.new(
        kind: :component,
        subcategory: :feedback,
        slug: "empty-state",
        title: "Empty state",
        description: "An explicit empty result with controlled heading hierarchy, icon, and up to two actions.",
        page: Gallery::Components::EmptyStatePage,
        states: [],
        expected_roots: %w[empty-state icon button container]
      ),
      Entry.new(
        kind: :composition,
        slug: "sign-in",
        title: "Sign in",
        description: "AuthShell-composed credential entry, validation, submission, success, and mobile pressure.",
        page: Gallery::Compositions::SignInPage,
        states: %w[default invalid loading success mobile],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "password-reset",
        title: "Password reset",
        description: "AuthShell-composed recovery request, delivery, replacement, expiration, and loading states.",
        page: Gallery::Compositions::PasswordResetPage,
        states: %w[request validation sent update expired loading],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "email-verification",
        title: "Email verification",
        description: "AuthShell-composed pending, verified, expired, invalid-token, and long-copy identity states.",
        page: Gallery::Compositions::EmailVerificationPage,
        states: %w[pending verified expired invalid-token long-copy],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "invitation-acceptance",
        title: "Invitation acceptance",
        description: "AuthShell-composed workspace invitation setup, validation, token recovery, completion, and mobile pressure.",
        page: Gallery::Compositions::InvitationAcceptancePage,
        states: %w[valid validation loading accepted expired invalid-token mobile],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "account-creation",
        title: "Account creation",
        description: "AuthShell-composed registration, consent, validation, submission, verification handoff, and content pressure.",
        page: Gallery::Compositions::AccountCreationPage,
        states: %w[default validation loading success long-copy mobile],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "onboarding",
        title: "Workspace onboarding",
        description: "AuthShell-composed workspace, team, integration, review, resume, validation, loading, and completion steps.",
        page: Gallery::Compositions::OnboardingPage,
        states: %w[workspace workspace-validation team integrations review loading complete resume mobile],
        expected_roots: %w[auth-shell container flex card button]
      ),
      Entry.new(
        kind: :composition,
        slug: "dashboard",
        title: "Workspace dashboard",
        description: "A component-composed dashboard with semantic chart pressure across new, active, degraded, loading, dense, and mobile states.",
        page: Gallery::Compositions::DashboardPage,
        states: %w[new active degraded loading dense mobile],
        expected_roots: %w[container flex page-header button]
      ),
      Entry.new(
        kind: :composition,
        slug: "settings",
        title: "Workspace settings",
        description: "Component-composed profile, security, notification, integration, and appearance settings.",
        page: Gallery::Compositions::SettingsPage,
        states: %w[
          profile profile-validation profile-success security security-disabled notifications notifications-success
          integrations integrations-empty integrations-error appearance appearance-loading long-content mobile
        ],
        expected_roots: %w[container flex settings-layout button]
      ),
      Entry.new(
        kind: :composition,
        slug: "billing",
        title: "Subscription billing",
        description: "Component-composed plan, payment, paginated invoice, cancellation, outcome, and mobile billing states.",
        page: Gallery::Compositions::BillingPage,
        states: %w[
          plans payment-method payment-validation payment-loading payment-updated invoices invoice-detail invoice-empty
          cancellation cancellation-validation cancellation-loading cancelled mobile
        ],
        expected_roots: %w[container flex button]
      ),
      Entry.new(
        kind: :composition,
        slug: "users",
        title: "Workspace users",
        description: "Component-composed paginated user index and search plus detail, empty, loading, error, bulk, outcome, and mobile states.",
        page: Gallery::Compositions::UsersPage,
        states: %w[index detail search empty loading error bulk bulk-confirmation bulk-complete mobile],
        expected_roots: %w[container flex button]
      ),
      Entry.new(
        kind: :composition,
        slug: "team-management",
        title: "Team management",
        description: "Component-composed member inventory, invitation, role, removal, outcome, density, and mobile states.",
        page: Gallery::Compositions::TeamManagementPage,
        states: %w[
          members search empty invite invite-validation loading role-change remove-confirmation removed error dense mobile
        ],
        expected_roots: %w[container flex button]
      ),
      Entry.new(
        kind: :composition,
        slug: "api-credentials",
        title: "API credentials",
        description: "Component-composed credential inventory, creation, reveal-once, revocation, recovery, density, and mobile states.",
        page: Gallery::Compositions::ApiCredentialsPage,
        states: %w[
          list empty create validation loading reveal-once revoke-confirmation revoked expired error long dense mobile
        ],
        expected_roots: %w[container flex button]
      ),
      Entry.new(
        kind: :composition,
        slug: "organization-overview",
        title: "Organization overview",
        description: "Component-composed organization identity, capacity, resource inventory, availability, density, and mobile states.",
        page: Gallery::Compositions::OrganizationOverviewPage,
        states: %w[active empty error dense long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "organization-settings",
        title: "Organization settings",
        description: "Component-composed identity, access, integration, validation, authorization, long-content, and mobile settings.",
        page: Gallery::Compositions::OrganizationSettingsPage,
        states: %w[general access integrations validation success error long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "team-activity",
        title: "Team activity",
        description: "Searchable and filterable organization access activity with empty, failure, density, long-content, and mobile states.",
        page: Gallery::Compositions::TeamActivityPage,
        states: %w[recent search filtered empty error dense long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "team-member",
        title: "Team member",
        description: "Member identity, lifecycle, caller-owned authorization, activity, missing, failure, long-content, and mobile states.",
        page: Gallery::Compositions::TeamMemberPage,
        states: %w[active invited suspended activity empty error long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "data-resource-overview",
        title: "Data resource overview",
        description: "Searchable and filterable resource inventory with bulk selection, empty, failure, density, long-content, and mobile states.",
        page: Gallery::Compositions::DataResourceOverviewPage,
        states: %w[index search filtered bulk empty error dense long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "data-resource-activity",
        title: "Data resource activity",
        description: "Resource-scoped operational activity with composed filters, empty, failure, density, long-content, and mobile states.",
        page: Gallery::Compositions::DataResourceActivityPage,
        states: %w[recent filtered empty error dense long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "data-resource-settings",
        title: "Data resource settings",
        description: "Resource configuration, access, validation, authorization, archival, long-content, and mobile settings states.",
        page: Gallery::Compositions::DataResourceSettingsPage,
        states: %w[general validation success access danger error long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "checkout",
        title: "Checkout and payment",
        description: "Component-composed order review, payment entry, provider outcomes, cancellation, refunds, and pressure states.",
        page: Gallery::Compositions::CheckoutPage,
        states: %w[
          review payment validation processing succeeded failed requires-action cancelled refunded empty-cart long mobile
        ],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "account-security",
        title: "Account security",
        description: "AuthShell-composed recovery, token expiry, locks, two-factor challenges, recovery codes, trust, and pressure states.",
        page: Gallery::Compositions::AccountSecurityPage,
        states: %w[
          recovery-request recovery-validation recovery-sent reset reset-expired account-locked unlock-sent
          two-factor-challenge two-factor-invalid recovery-code recovery-code-invalid trusted-device loading success long mobile
        ],
        expected_roots: %w[auth-shell page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "onboarding-branches",
        title: "Branched onboarding",
        description: "Component-composed company, personal, and import branches with explicit skips, reviews, resume, and outcomes.",
        page: Gallery::Compositions::OnboardingBranchesPage,
        states: %w[
          choose-path company solo import invite-team skip-team integration skip-integration review-company review-solo
          validation saving complete resume long mobile
        ],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "api-webhooks",
        title: "API webhooks",
        description: "Component-composed endpoint inventory, configuration, signing secrets, deliveries, failures, retries, and pressure states.",
        page: Gallery::Compositions::ApiWebhooksPage,
        states: %w[
          list empty detail create validation loading delivery-succeeded delivery-failed retrying disabled signing-secret
          dense long mobile
        ],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "integration-management",
        title: "Integration management",
        description: "Component-composed provider catalog, detail, connected inventory, configuration recovery, and mobile states.",
        page: Gallery::Compositions::IntegrationManagementPage,
        states: %w[catalog detail connected config-error mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "uploads",
        title: "File uploads",
        description: "Rails-native multipart upload forms across empty, uploading, complete, rejected, multiple, long, and mobile states.",
        page: Gallery::Compositions::UploadsPage,
        states: %w[empty uploading complete error multiple long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "activity-audit",
        title: "Activity and audit log",
        description: "Searchable workspace audit history across normal, filtered, empty, dense, failure, and mobile states.",
        page: Gallery::Compositions::ActivityAuditPage,
        states: %w[normal filter empty dense error mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "changelog",
        title: "Changelog",
        description: "Component-composed latest release, archive, empty, long-content, and mobile documentation states.",
        page: Gallery::Compositions::ChangelogPage,
        states: %w[latest archive empty long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "help-center",
        title: "Help center",
        description: "FAQ, search, zero-result, support contact, validation, outcome, long-content, and mobile states.",
        page: Gallery::Compositions::HelpCenterPage,
        states: %w[faq search empty contact contact-validation contact-sent long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "system-status",
        title: "System status and errors",
        description: "Caller-owned HTTP failures, maintenance, connectivity, rate limits, degradation, and pressure states.",
        page: Gallery::Compositions::SystemStatusPage,
        states: %w[403 404 422 500 maintenance offline rate-limited degraded long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "landing",
        title: "Product landing",
        description: "A directly composed public landing page with announcement, proof, long-content, and mobile states.",
        page: Gallery::Compositions::LandingPage,
        states: %w[default announcement customer-proof long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "pricing",
        title: "Public pricing",
        description: "Monthly, annual, comparison, enterprise, long-content, and mobile pricing compositions.",
        page: Gallery::Compositions::PricingPage,
        states: %w[monthly annual comparison enterprise long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "features",
        title: "Product features",
        description: "Overview, security, automation, collaboration, long-content, and mobile feature compositions.",
        page: Gallery::Compositions::FeaturesPage,
        states: %w[overview security automation collaboration long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "contact",
        title: "Public contact",
        description: "A Rails-native public inquiry across validation, submission, result, availability, and pressure states.",
        page: Gallery::Compositions::ContactPage,
        states: %w[form validation sending sent unavailable long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "checkout-result",
        title: "Checkout results",
        description: "Invoice, bank transfer, trial, account credit, manual review, long-content, and mobile outcomes.",
        page: Gallery::Compositions::CheckoutResultPage,
        states: %w[invoice-issued bank-transfer-pending trial-started credit-applied manual-review long mobile],
        expected_roots: %w[page-header container flex button-group button]
      ),
      Entry.new(
        kind: :composition,
        slug: "application-sidebar",
        title: "Sidebar operations application",
        description: "A realistic sidebar application combining appearance, data, upload, notification, recovery, and empty-state workflows.",
        page: Gallery::Compositions::SidebarApplicationPage,
        states: [],
        expected_roots: %w[
          app-shell app-navigation page-header appearance-picker stat-grid toast data-section empty-state
          dropzone form-section alert details-table dialog container flex button
        ]
      ),
      Entry.new(
        kind: :composition,
        slug: "application-topbar",
        title: "Topbar media application",
        description: "A realistic topbar application combining progressive media, record menus, loading feedback, long data, dialogs, and notifications.",
        page: Gallery::Compositions::TopbarApplicationPage,
        states: [],
        expected_roots: %w[
          app-shell app-navigation page-header grid card progressive-image dropdown toast alert dialog
          container flex button
        ]
      ),
      Entry.new(
        kind: :composition,
        slug: "application-hybrid",
        title: "Hybrid account application",
        description: "A realistic hybrid application combining synchronized appearance, profile media, record details, forms, missing data, policy errors, and overlays.",
        page: Gallery::Compositions::HybridApplicationPage,
        states: [],
        expected_roots: %w[
          app-shell app-navigation page-header appearance-picker settings-layout progressive-image details-table form-section
          fieldset field-group field input empty-state alert dialog toast dropdown container flex button
        ]
      )
    ].freeze

    # Which `docs/patterns/*.md` conventions a component page inlines.
    # Declared once as data so no page grows its own conditional.
    PATTERNS = {
      [ :component, "alert" ] => %w[flash_and_toast],
      [ :component, "app-navigation" ] => %w[application_foundation],
      [ :component, "app-shell" ] => %w[application_foundation crud_resource],
      [ :component, "auth-shell" ] => %w[application_foundation],
      [ :component, "card" ] => %w[inline_edit],
      [ :component, "checkbox" ] => %w[resource_form],
      [ :component, "checkbox-group" ] => %w[resource_form],
      [ :component, "combobox" ] => %w[resource_form],
      [ :component, "danger-zone" ] => %w[destructive_action],
      [ :component, "data-section" ] => %w[queryable_collection crud_resource],
      [ :component, "details-table" ] => %w[inline_edit crud_resource],
      [ :component, "dialog" ] => %w[destructive_action],
      [ :component, "dropzone" ] => %w[resource_form],
      [ :component, "empty-state" ] => %w[crud_resource],
      [ :component, "field" ] => %w[resource_form],
      [ :component, "field-group" ] => %w[resource_form],
      [ :component, "fieldset" ] => %w[resource_form],
      [ :component, "form-section" ] => %w[resource_form crud_resource],
      [ :component, "input" ] => %w[resource_form],
      [ :component, "label" ] => %w[resource_form],
      [ :component, "page-header" ] => %w[crud_resource],
      [ :component, "pagination" ] => %w[queryable_collection],
      [ :component, "pagination-bar" ] => %w[queryable_collection],
      [ :component, "radio-button" ] => %w[resource_form],
      [ :component, "radio-button-group" ] => %w[resource_form],
      [ :component, "rich-text-area" ] => %w[resource_form],
      [ :component, "select" ] => %w[resource_form],
      [ :component, "settings-layout" ] => %w[application_foundation],
      [ :component, "switch" ] => %w[resource_form],
      [ :component, "table" ] => %w[queryable_collection],
      [ :component, "textarea" ] => %w[resource_form],
      [ :component, "toast" ] => %w[flash_and_toast],
      [ :component, "toolbar" ] => %w[queryable_collection crud_resource]
    }.freeze

    entry_index = ENTRIES.to_h { |entry| [ [ entry.kind, entry.slug ], entry ] }
    pick_entries = lambda do |kind, *slugs|
      slugs.map { |slug| entry_index.fetch([ kind, slug ]) }.freeze
    end

    # Component subcategories, in sidebar order. Every component entry declares
    # exactly one of these slugs.
    SUBCATEGORIES = [
      [ :layout, "Layout", "Page frames, shells, and content structure." ],
      [ :navigation, "Navigation", "Destination trees, tabs, toolbars, and pagination." ],
      [ :forms, "Forms", "Controls, fields, and form structure." ],
      [ :data, "Data display", "Tables, records, media, and identity." ],
      [ :feedback, "Feedback", "Status, guidance, and empty results." ],
      [ :actions, "Actions", "Buttons, menus, overlays, and destructive intent." ]
    ].freeze

    COLLECTIONS = [
      Collection.new(
        kind: :component,
        title: "Components",
        description: "Every gem-owned component, exhaustively permuted.",
        categories: SUBCATEGORIES.map do |slug, title, description|
          Category.new(
            slug: slug.to_s,
            title:,
            description:,
            entries: ENTRIES
              .select { |entry| entry.kind == :component && entry.subcategory == slug }
              .sort_by { |entry| entry.title.downcase }
              .freeze
          )
        end.freeze
      ),
      Collection.new(
        kind: :composition,
        title: "Compositions",
        description: "Executable composition tests: the system exercised whole.",
        categories: [
          Category.new(
            slug: "access-and-onboarding",
            title: "Access & onboarding",
            description: "Account entry, recovery, verification, invitations, security, and setup.",
            entries: pick_entries.call(
              :composition,
              "sign-in",
              "password-reset",
              "email-verification",
              "invitation-acceptance",
              "account-creation",
              "account-security",
              "onboarding",
              "onboarding-branches"
            )
          ),
          Category.new(
            slug: "workspace-and-organization",
            title: "Workspace & organization",
            description: "Daily administration, people, settings, and credentials.",
            entries: pick_entries.call(
              :composition,
              "dashboard",
              "settings",
              "users",
              "team-management",
              "api-credentials",
              "organization-overview",
              "organization-settings",
              "team-activity",
              "team-member"
            )
          ),
          Category.new(
            slug: "billing-and-commerce",
            title: "Billing & commerce",
            description: "Subscription management, checkout, and payment outcomes.",
            entries: pick_entries.call(:composition, "billing", "checkout", "checkout-result")
          ),
          Category.new(
            slug: "data-and-operations",
            title: "Data & operations",
            description: "Resources, integrations, uploads, webhooks, and audit activity.",
            entries: pick_entries.call(
              :composition,
              "data-resource-overview",
              "data-resource-activity",
              "data-resource-settings",
              "api-webhooks",
              "integration-management",
              "uploads",
              "activity-audit"
            )
          ),
          Category.new(
            slug: "product-and-support",
            title: "Product & support",
            description: "Product communication, help, and system states.",
            entries: pick_entries.call(:composition, "changelog", "help-center", "system-status")
          ),
          Category.new(
            slug: "marketing",
            title: "Marketing",
            description: "Public acquisition, pricing, feature, and contact pages.",
            entries: pick_entries.call(:composition, "landing", "pricing", "features", "contact")
          ),
          Category.new(
            slug: "complete-applications",
            title: "Complete applications",
            description: "End-to-end sidebar, topbar, and hybrid application compositions.",
            entries: pick_entries.call(
              :composition,
              "application-sidebar",
              "application-topbar",
              "application-hybrid"
            )
          )
        ].freeze
      )
    ].freeze

    ORDERED_ENTRIES = [ ENTRIES.first, *COLLECTIONS.flat_map(&:entries) ].freeze
    ENTRY_INDEX = entry_index.freeze

    module_function

    def home
      ORDERED_ENTRIES.first
    end

    def entries(kind: nil)
      return ORDERED_ENTRIES unless kind

      normalized_kind = kind.to_sym
      return [ home ] if normalized_kind == :home

      COLLECTIONS.find { |collection| collection.kind == normalized_kind }&.entries || []
    end

    def collections
      COLLECTIONS
    end

    def collection!(kind)
      COLLECTIONS.find { |collection| collection.kind == kind.to_sym } ||
        raise(CollectionNotFound, "Unknown gallery collection #{kind.inspect}")
    end

    def category!(kind:, slug:)
      collection!(kind).categories.find { |category| category.slug == slug.to_s } ||
        raise(CategoryNotFound, "Unknown #{kind} gallery category #{slug.inspect}")
    end

    def category_for(entry)
      collection = COLLECTIONS.find { |candidate| candidate.kind == entry.kind }
      collection&.categories&.find { |category| category.entries.include?(entry) }
    end

    def fetch!(kind:, slug:)
      ENTRY_INDEX[[ kind.to_sym, slug.to_s ]] ||
        raise(EntryNotFound, "Unknown #{kind} gallery entry #{slug.inspect}")
    end

    def resolve_state!(entry, state)
      return if entry.states.empty? && state.blank?

      resolved_state = state.presence || entry.states.first
      return resolved_state if entry.states.include?(resolved_state)

      raise StateNotFound, "Unknown state #{state.inspect} for #{entry.slug.inspect}"
    end

    def patterns_for(entry)
      PATTERNS.fetch([ entry.kind, entry.slug ], []).map { |slug| Gallery::Patterns.fetch!(slug) }
    end

    def path_for(entry, routes:, state: nil)
      case entry.kind
      when :home
        routes.gallery_root_path
      when :component
        routes.gallery_component_path(entry.slug)
      when :composition
        routes.gallery_composition_path(slug: entry.slug, state: state || entry.states.first)
      else
        raise ArgumentError, "Unknown gallery entry kind #{entry.kind.inspect}"
      end
    end
  end
end
