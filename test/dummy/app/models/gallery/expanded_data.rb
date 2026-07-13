module Gallery
  module ExpandedData
    Organization = ::Data.define(
      :id,
      :name,
      :slug,
      :plan,
      :region,
      :member_count,
      :resource_count,
      :storage_gb,
      :status,
      :owner_email,
      :created_on
    )
    TeamEvent = ::Data.define(:id, :member_id, :member_name, :action, :subject, :outcome, :occurred_at)
    Resource = ::Data.define(
      :id,
      :name,
      :kind,
      :owner,
      :status,
      :record_count,
      :retention_days,
      :updated_at,
      :description
    )
    ResourceEvent = ::Data.define(:id, :resource_id, :resource_name, :actor, :action, :outcome, :occurred_at)

    ORGANIZATION = Organization.new(
      id: "org_analytical",
      name: "Analytical Engines — Research and Production",
      slug: "analytical-engines",
      plan: "Scale",
      region: "Europe North",
      member_count: 128,
      resource_count: 24,
      storage_gb: 842,
      status: :operational,
      owner_email: "ada@analytical-engines.example.test",
      created_on: Date.new(2024, 1, 8)
    )

    TEAM_EVENTS = [
      TeamEvent.new(
        id: "team_evt_1",
        member_id: "mem_grace",
        member_name: "Grace Hopper",
        action: "changed the production deployment policy",
        subject: "Production workspace",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-13 08:45:00")
      ),
      TeamEvent.new(
        id: "team_evt_2",
        member_id: "mem_ada",
        member_name: "Ada Lovelace",
        action: "invited an organization administrator",
        subject: "dorothy.vaughan@example.test",
        outcome: :pending,
        occurred_at: Time.zone.parse("2026-07-13 08:12:00")
      ),
      TeamEvent.new(
        id: "team_evt_3",
        member_id: "mem_margaret",
        member_name: "Margaret Hamilton",
        action: "exported a member access report",
        subject: "Quarterly security review",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-12 16:20:00")
      ),
      TeamEvent.new(
        id: "team_evt_4",
        member_id: "mem_annie",
        member_name: "Annie Easley",
        action: "attempted to rotate recovery credentials",
        subject: "Suspended member account",
        outcome: :blocked,
        occurred_at: Time.zone.parse("2026-07-12 13:05:00")
      ),
      TeamEvent.new(
        id: "team_evt_5",
        member_id: "mem_grace",
        member_name: "Grace Hopper",
        action: "approved a role change",
        subject: "International Research administrators",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-11 09:40:00")
      ),
      TeamEvent.new(
        id: "team_evt_6",
        member_id: "mem_ada",
        member_name: "Ada Lovelace",
        action: "revoked an inactive browser session",
        subject: "Chrome 142 · London",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-10 18:15:00")
      )
    ].freeze

    RESOURCES = [
      Resource.new(
        id: "res_customers",
        name: "Customer accounts",
        kind: :dataset,
        owner: "Customer Operations",
        status: :healthy,
        record_count: 48_291,
        retention_days: 365,
        updated_at: Time.zone.parse("2026-07-13 08:58:00"),
        description: "Verified customer identity, plan, and lifecycle records."
      ),
      Resource.new(
        id: "res_deployments",
        name: "Production deployments",
        kind: :stream,
        owner: "Reliability Engineering",
        status: :healthy,
        record_count: 12_804,
        retention_days: 180,
        updated_at: Time.zone.parse("2026-07-13 08:51:00"),
        description: "Immutable production release events and rollback metadata."
      ),
      Resource.new(
        id: "res_invoices",
        name: "Invoice ledger",
        kind: :dataset,
        owner: "Finance",
        status: :healthy,
        record_count: 8_442,
        retention_days: 2_555,
        updated_at: Time.zone.parse("2026-07-13 07:30:00"),
        description: "Paid, refunded, and scheduled organization invoices."
      ),
      Resource.new(
        id: "res_audit",
        name: "Administrative audit trail",
        kind: :stream,
        owner: "Security",
        status: :degraded,
        record_count: 1_284_320,
        retention_days: 730,
        updated_at: Time.zone.parse("2026-07-13 08:42:00"),
        description: "Organization access and security policy mutations."
      ),
      Resource.new(
        id: "res_catalog",
        name: "Integration catalog",
        kind: :index,
        owner: "Developer Experience",
        status: :syncing,
        record_count: 184,
        retention_days: 90,
        updated_at: Time.zone.parse("2026-07-13 08:22:00"),
        description: "Installable external services and compatibility metadata."
      ),
      Resource.new(
        id: "res_archive",
        name: "Legacy research archive",
        kind: :archive,
        owner: "Research Operations",
        status: :read_only,
        record_count: 92_118,
        retention_days: 3_650,
        updated_at: Time.zone.parse("2026-06-29 12:00:00"),
        description: "Historical analytical engine experiments retained for compliance."
      )
    ].freeze

    RESOURCE_EVENTS = [
      ResourceEvent.new(
        id: "resource_evt_1",
        resource_id: "res_customers",
        resource_name: "Customer accounts",
        actor: "Customer Operations",
        action: "imported 418 verified account updates",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-13 08:58:00")
      ),
      ResourceEvent.new(
        id: "resource_evt_2",
        resource_id: "res_audit",
        resource_name: "Administrative audit trail",
        actor: "Security pipeline",
        action: "delayed regional replication for 94 seconds",
        outcome: :warning,
        occurred_at: Time.zone.parse("2026-07-13 08:42:00")
      ),
      ResourceEvent.new(
        id: "resource_evt_3",
        resource_id: "res_deployments",
        resource_name: "Production deployments",
        actor: "Grace Hopper",
        action: "recorded release nk-web-2026.07.13.3",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-13 08:31:00")
      ),
      ResourceEvent.new(
        id: "resource_evt_4",
        resource_id: "res_catalog",
        resource_name: "Integration catalog",
        actor: "Catalog synchronizer",
        action: "started a complete provider metadata refresh",
        outcome: :pending,
        occurred_at: Time.zone.parse("2026-07-13 08:22:00")
      ),
      ResourceEvent.new(
        id: "resource_evt_5",
        resource_id: "res_invoices",
        resource_name: "Invoice ledger",
        actor: "Finance automation",
        action: "closed the June 2026 accounting period",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-13 07:30:00")
      ),
      ResourceEvent.new(
        id: "resource_evt_6",
        resource_id: "res_archive",
        resource_name: "Legacy research archive",
        actor: "Research Operations",
        action: "verified annual retention and legal-hold policy",
        outcome: :success,
        occurred_at: Time.zone.parse("2026-07-12 15:10:00")
      )
    ].freeze

    module_function

    def organization = ORGANIZATION

    def team_events(query: nil, outcome: nil)
      filter(TEAM_EVENTS, query:, outcome:) { |event| [ event.member_name, event.action, event.subject ] }
    end

    def resources(query: nil, status: nil, kind: nil)
      filter(RESOURCES, query:, status:, kind:) { |resource| [ resource.name, resource.owner, resource.description ] }
    end

    def resource_events(query: nil, outcome: nil, resource_id: nil)
      filter(RESOURCE_EVENTS, query:, outcome:, resource_id:) do |event|
        [ event.resource_name, event.actor, event.action ]
      end
    end

    def filter(records, query: nil, **attributes)
      matches = records
      if query.present?
        needle = query.downcase
        matches = matches.select { |record| yield(record).any? { |value| value.downcase.include?(needle) } }
      end
      attributes.compact.each do |attribute, value|
        matches = matches.select { |record| record.public_send(attribute).to_s == value.to_s }
      end
      matches
    end
    private_class_method :filter
  end
end
