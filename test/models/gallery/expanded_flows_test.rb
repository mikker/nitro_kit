require "test_helper"

class Gallery::ExpandedFlowsTest < ActiveSupport::TestCase
  test "organization team and resource records are fixed unique inventories" do
    organization = Gallery::ExpandedData.organization
    team_events = Gallery::ExpandedData.team_events
    resources = Gallery::ExpandedData.resources
    resource_events = Gallery::ExpandedData.resource_events

    assert_equal "org_analytical", organization.id
    assert_equal "Analytical Engines — Research and Production", organization.name
    assert_equal 6, team_events.size
    assert_equal 6, resources.size
    assert_equal 6, resource_events.size
    assert_equal team_events.map(&:id).uniq, team_events.map(&:id)
    assert_equal resources.map(&:id).uniq, resources.map(&:id)
    assert_equal resource_events.map(&:id).uniq, resource_events.map(&:id)
    assert Gallery::ExpandedData::TEAM_EVENTS.frozen?
    assert Gallery::ExpandedData::RESOURCES.frozen?
    assert Gallery::ExpandedData::RESOURCE_EVENTS.frozen?
  end

  test "query methods compose free text and typed attributes without changing source data" do
    assert_equal %w[team_evt_1 team_evt_5], Gallery::ExpandedData.team_events(query: "Grace", outcome: :success).map(&:id)
    assert_equal %w[team_evt_4], Gallery::ExpandedData.team_events(outcome: "blocked").map(&:id)
    assert_equal %w[res_deployments], Gallery::ExpandedData.resources(query: "production", kind: "stream").map(&:id)
    assert_equal %w[res_customers res_invoices], Gallery::ExpandedData.resources(
      status: "healthy",
      kind: "dataset"
    ).map(&:id)
    assert_equal %w[resource_evt_2], Gallery::ExpandedData.resource_events(
      query: "replication",
      outcome: :warning,
      resource_id: "res_audit"
    ).map(&:id)
    assert_equal 6, Gallery::ExpandedData.resources.size
  end

  test "expanded forms validate search settings and destructive bulk intent" do
    organization = Gallery::Forms::OrganizationSettings.new(
      name: "Analytical Engines",
      slug: "analytical-engines",
      default_role: "member",
      security_notifications: true
    )
    resources = Gallery::Forms::ResourceSearch.new(query: "audit", status: "degraded", kind: "stream")
    activity = Gallery::Forms::ResourceActivityFilter.new(
      query: "replication",
      outcome: "warning",
      resource_id: "res_audit"
    )
    settings = Gallery::Forms::ResourceSettings.new(
      name: "Customer accounts",
      visibility: "organization",
      retention_days: 365,
      notify_failures: true
    )
    export = Gallery::Forms::ResourceBulkAction.new(resource_ids: [ "res_customers" ], action: "export")
    archive = Gallery::Forms::ResourceBulkAction.new(
      resource_ids: [ "res_customers" ],
      action: "archive",
      confirmed: false
    )

    assert_predicate organization, :valid?
    assert_predicate resources, :valid?
    assert_predicate activity, :valid?
    assert_predicate settings, :valid?
    assert_predicate export, :valid?
    assert_predicate archive, :invalid?
    assert archive.errors.of_kind?(:confirmed, :accepted)

    organization.assign_attributes(name: "", slug: "Not a slug", default_role: "owner")
    resources.assign_attributes(status: "lost", kind: "unknown")
    activity.outcome = "unknown"
    settings.assign_attributes(name: "", retention_days: 31)

    assert_predicate organization, :invalid?
    assert_equal %i[name slug default_role], organization.errors.attribute_names
    assert_predicate resources, :invalid?
    assert_equal %i[status kind], resources.errors.attribute_names
    assert_predicate activity, :invalid?
    assert_equal [ :outcome ], activity.errors.attribute_names
    assert_predicate settings, :invalid?
    assert_equal %i[name retention_days], settings.errors.attribute_names
  end

  test "caller policy distinguishes inspection management and destructive authority" do
    owner = Gallery::ExpandedAccessPolicy.new(role: :owner)
    administrator = Gallery::ExpandedAccessPolicy.new(role: :administrator)
    member = Gallery::ExpandedAccessPolicy.new(role: :member)
    syncing_resource = Gallery::ExpandedData.resources.find { |resource| resource.status == :syncing }
    healthy_resource = Gallery::ExpandedData.resources.find { |resource| resource.status == :healthy }

    assert owner.manage_organization?
    assert owner.manage_team?
    assert owner.bulk_resources?
    assert owner.delete_resource?(healthy_resource)
    assert_not owner.delete_resource?(syncing_resource)
    assert administrator.manage_resources?
    assert_not administrator.delete_resource?(healthy_resource)
    assert_not member.manage_resources?
    assert_not member.bulk_resources?
    assert_raises(ArgumentError) { Gallery::ExpandedAccessPolicy.new(role: :invented) }
  end
end
