module Gallery
  module OperationalData
    IntegrationProvider = ::Data.define(
      :id,
      :name,
      :category,
      :status,
      :summary,
      :connected_at,
      :documentation_url
    )
    UploadRecord = ::Data.define(
      :id,
      :filename,
      :size_bytes,
      :content_type,
      :status,
      :uploaded_by,
      :uploaded_at
    )
    AuditEvent = ::Data.define(
      :id,
      :actor,
      :action,
      :subject,
      :category,
      :outcome,
      :ip_address,
      :occurred_at
    )
    ChangelogEntry = ::Data.define(:id, :version, :released_on, :title, :summary, :changes)
    HelpQuestion = ::Data.define(:id, :category, :question, :answer)

    INTEGRATION_PROVIDERS = [
      IntegrationProvider.new(
        id: "provider_github",
        name: "GitHub",
        category: :source_control,
        status: :connected,
        summary: "Sync pull requests, deployments, and release metadata from selected repositories.",
        connected_at: Time.zone.parse("2026-02-14 15:20:00"),
        documentation_url: "https://docs.example.test/integrations/github"
      ),
      IntegrationProvider.new(
        id: "provider_slack",
        name: "Slack",
        category: :notifications,
        status: :configuration_error,
        summary: "Deliver release, incident, billing, and security notifications to workspace channels.",
        connected_at: Time.zone.parse("2026-04-18 11:45:00"),
        documentation_url: "https://docs.example.test/integrations/slack"
      ),
      IntegrationProvider.new(
        id: "provider_sentry",
        name: "Sentry",
        category: :observability,
        status: :available,
        summary: "Associate application errors with deployments and workspace release history.",
        connected_at: nil,
        documentation_url: "https://docs.example.test/integrations/sentry"
      ),
      IntegrationProvider.new(
        id: "provider_datadog",
        name: "Datadog",
        category: :observability,
        status: :available,
        summary: "Link monitors, incidents, and service ownership to production environments.",
        connected_at: nil,
        documentation_url: "https://docs.example.test/integrations/datadog"
      )
    ].freeze

    UPLOADS = [
      UploadRecord.new(
        id: "upload_accounts",
        filename: "customer-accounts-2026-07-13.csv",
        size_bytes: 4_821_992,
        content_type: "text/csv",
        status: :complete,
        uploaded_by: "Ada Lovelace",
        uploaded_at: Time.zone.parse("2026-07-13 09:18:00")
      ),
      UploadRecord.new(
        id: "upload_events",
        filename: "production-deployment-events.ndjson",
        size_bytes: 18_204_112,
        content_type: "application/x-ndjson",
        status: :processing,
        uploaded_by: "Grace Hopper",
        uploaded_at: Time.zone.parse("2026-07-13 09:24:00")
      ),
      UploadRecord.new(
        id: "upload_archive",
        filename: "international-research-production-reliability-and-regulatory-archive-2026-07-13.zip",
        size_bytes: 96_102_440,
        content_type: "application/zip",
        status: :queued,
        uploaded_by: "Katherine Johnson",
        uploaded_at: Time.zone.parse("2026-07-13 09:26:00")
      )
    ].freeze

    AUDIT_EVENTS = [
      AuditEvent.new(
        id: "audit_credential",
        actor: "Ada Lovelace",
        action: "revoked a production API credential",
        subject: "nk_live_7P3F",
        category: :security,
        outcome: :success,
        ip_address: "192.0.2.42",
        occurred_at: Time.zone.parse("2026-07-13 09:31:00")
      ),
      AuditEvent.new(
        id: "audit_integration",
        actor: "Grace Hopper",
        action: "updated notification routing",
        subject: "Slack · #production-incidents",
        category: :integration,
        outcome: :warning,
        ip_address: "198.51.100.17",
        occurred_at: Time.zone.parse("2026-07-13 09:12:00")
      ),
      AuditEvent.new(
        id: "audit_upload",
        actor: "Katherine Johnson",
        action: "started a regulated archive upload",
        subject: "Research archive import",
        category: :data,
        outcome: :pending,
        ip_address: "203.0.113.28",
        occurred_at: Time.zone.parse("2026-07-13 08:54:00")
      ),
      AuditEvent.new(
        id: "audit_role",
        actor: "Ada Lovelace",
        action: "changed a workspace role from member to administrator",
        subject: "Grace Hopper",
        category: :access,
        outcome: :success,
        ip_address: "192.0.2.42",
        occurred_at: Time.zone.parse("2026-07-12 16:03:00")
      ),
      AuditEvent.new(
        id: "audit_export",
        actor: "Finance automation",
        action: "exported a paid invoice ledger",
        subject: "June 2026 accounting period",
        category: :billing,
        outcome: :success,
        ip_address: "203.0.113.91",
        occurred_at: Time.zone.parse("2026-07-12 13:18:00")
      ),
      AuditEvent.new(
        id: "audit_blocked",
        actor: "Annie Easley",
        action: "attempted to rotate recovery credentials",
        subject: "Suspended member account",
        category: :security,
        outcome: :blocked,
        ip_address: "198.51.100.88",
        occurred_at: Time.zone.parse("2026-07-11 19:44:00")
      )
    ].freeze

    CHANGELOG_ENTRIES = [
      ChangelogEntry.new(
        id: "release_2_0_0_beta_3",
        version: "2.0.0-beta.3",
        released_on: Date.new(2026, 7, 13),
        title: "Typed application sections",
        summary: "Adds explicit data, form, navigation, and safety compositions for Rails applications.",
        changes: [
          "Added DataSection, FormSection, DangerZone, and EmptyState.",
          "Added deterministic Container, responsive Grid, and Flex layouts.",
          "Expanded direct Phlex gallery coverage for application pressure states."
        ].freeze
      ),
      ChangelogEntry.new(
        id: "release_2_0_0_beta_2",
        version: "2.0.0-beta.2",
        released_on: Date.new(2026, 7, 6),
        title: "Rails-native form composition",
        summary: "Moves form rendering to direct Phlex while preserving Rails naming and multipart behavior.",
        changes: [
          "Reworked FormBuilder around explicit fields and fieldsets.",
          "Preserved native validation, file input, and autocomplete semantics."
        ].freeze
      ),
      ChangelogEntry.new(
        id: "release_2_0_0_beta_1",
        version: "2.0.0-beta.1",
        released_on: Date.new(2026, 6, 29),
        title: "Agent-native component kernel",
        summary: "Introduces self-describing markup, closed Ruby options, and gem-owned CSS.",
        changes: [
          "Added data-nk component identity and qualified slots.",
          "Removed template helpers and copied-component generation."
        ].freeze
      )
    ].freeze

    HELP_QUESTIONS = [
      HelpQuestion.new(
        id: "faq_uploads",
        category: :data,
        question: "Which files can I upload?",
        answer: "Workspace owners may upload CSV, NDJSON, JSON, and ZIP files up to the application-owned limit."
      ),
      HelpQuestion.new(
        id: "faq_integrations",
        category: :integrations,
        question: "Why does an integration need to be reconnected?",
        answer: "Provider authorization can expire or lose required scopes. Reconnecting creates a new application-owned grant."
      ),
      HelpQuestion.new(
        id: "faq_audit",
        category: :security,
        question: "How long is audit history retained?",
        answer: "The Scale plan retains workspace security and access events for 730 days."
      ),
      HelpQuestion.new(
        id: "faq_billing",
        category: :billing,
        question: "Where can I download paid invoices?",
        answer: "Workspace owners can download each immutable PDF from Billing → Invoice history."
      ),
      HelpQuestion.new(
        id: "faq_support",
        category: :support,
        question: "When will support reply?",
        answer: "Priority support acknowledges production incidents within one hour and other requests within one business day."
      )
    ].freeze

    module_function

    def integration_providers = INTEGRATION_PROVIDERS
    def uploads = UPLOADS
    def audit_events = AUDIT_EVENTS
    def changelog_entries = CHANGELOG_ENTRIES
    def help_questions = HELP_QUESTIONS
  end
end
