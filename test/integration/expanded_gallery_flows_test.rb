require "test_helper"

class ExpandedGalleryFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "organization-overview" => %w[active empty error dense long mobile],
    "organization-settings" => %w[general access integrations validation success error long mobile],
    "team-activity" => %w[recent search filtered empty error dense long mobile],
    "team-member" => %w[active invited suspended activity empty error long mobile],
    "data-resource-overview" => %w[index search filtered bulk empty error dense long mobile],
    "data-resource-activity" => %w[recent filtered empty error dense long mobile],
    "data-resource-settings" => %w[general validation success access danger error long mobile]
  }.freeze

  test "catalog exposes exact additive routes for expanded organization team and resource flows" do
    expanded_slugs = Gallery::Catalog.entries(kind: :flow).map(&:slug).select { |slug| FLOW_STATES.key?(slug) }
    assert_equal FLOW_STATES.keys, expanded_slugs

    FLOW_STATES.each do |slug, states|
      entry = Gallery::Catalog.fetch!(kind: :flow, slug:)

      assert_equal states, entry.states
      assert_equal %w[page-header container v-stack button-group button], entry.expected_roots
      states.each do |state|
        assert_equal "/gallery/flows/#{slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end

    get gallery_flow_path(slug: "data-resource-overview", state: "invented")
    assert_response :not_found
  end

  test "every expanded state renders in both themes through leak-free accepted structures" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        %w[light dark].each do |theme|
          get_flow(slug, state, theme:)

          assert_select "html[data-theme='#{theme}']"
          assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
          assert_select "[data-gallery-flow='#{slug}'][data-gallery-flow-state='#{state}']" do
            assert_select "[data-nk='container'][data-size='xl'] > [data-nk='v-stack'][data-gap='lg']" do
              assert_select "> [data-nk='page-header']", count: 1
            end
          end
          assert_select "nav[aria-label='#{flow_title(slug)} states'] a[aria-current='page']", count: 1
          assert_select "[data-gallery='example-canvas'] [class]", count: 0
          assert_select "[data-gallery='example-canvas'] [style]", count: 0
          assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
          assert_labelled_controls
        end
      end
    end
  end

  test "organization overview distinguishes operational empty failure and pressure states" do
    get_flow("organization-overview", "active")
    assert_select "#gallery-organization-overview-stats [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-organization-overview-resource-table tbody tr", count: 6
    assert_select "#gallery-organization-overview-pagination-bar[data-nk='pagination-bar']"

    get_flow("organization-overview", "empty")
    assert_select "#gallery-organization-overview-empty[data-nk='empty-state']", text: /No organization resources yet/
    assert_select "#gallery-organization-overview-resource-table", count: 0

    get_flow("organization-overview", "error")
    assert_select "#gallery-organization-overview-error[data-variant='error']", text: /temporarily unavailable/
    assert_select "#gallery-organization-overview-empty", text: /could not be loaded/

    get_flow("organization-overview", "dense")
    assert_select "#gallery-organization-overview-stats [data-slot='stat-grid-stat']", count: 6
    assert_select "#gallery-organization-overview-resource-table tbody tr", count: 12

    get_flow("organization-overview", "mobile")
    assert_select "[data-gallery-mobile='true']"
    assert_select "#gallery-organization-overview-resource-table thead th", count: 3
  end

  test "organization settings use real values validation policy and stable regions" do
    get_flow("organization-settings", "general")
    assert_select "#gallery-organization-settings-layout[data-nk='settings-layout']"
    assert_select "#gallery-organization-settings-navigation [aria-current='page']", text: "General"
    assert_select "#organization_name[value='Analytical Engines — Research and Production'][required]"
    assert_select "#organization_slug[value='analytical-engines'][required]"
    assert_select "#organization_security_notifications[role='switch'][checked]"

    get_flow("organization-settings", "validation")
    assert_select "#gallery-organization-settings-validation[data-variant='error']", text: /Slug/
    assert_select "#organization_slug[aria-invalid='true'][value='Not a valid slug']"

    get_flow("organization-settings", "success")
    assert_select "#gallery-organization-settings-success[data-variant='success']"
    assert_select "#gallery-organization-settings-form", count: 1

    get_flow("organization-settings", "error")
    assert_select "#gallery-organization-settings-policy[data-variant='warning']"
    assert_select "#gallery-organization-settings-fieldset[disabled]"
    assert_select "#gallery-organization-settings-submit[disabled]"

    get_flow("organization-settings", "access")
    assert_select "#gallery-organization-settings-access-table tbody tr", count: Gallery::Data.members.size

    get_flow("organization-settings", "integrations")
    assert_select "#gallery-organization-settings-integrations-table tbody tr", count: Gallery::Data.integrations.size
  end

  test "team activity composes query outcome empty error density and mobile semantics" do
    get_flow("team-activity", "search")
    assert_select "#activity_query[type='search'][value='Grace']"
    assert_select "#gallery-team-activity-table tbody tr", count: 2
    assert_select "#gallery-team-activity-pagination a[href*='activity%5Bquery%5D=Grace']", minimum: 1

    get_flow("team-activity", "filtered")
    assert_select "#activity_outcome option[value='blocked'][selected]"
    assert_select "#gallery-team-activity-table tbody tr", count: 1
    assert_select "#gallery-team-activity-pagination a[href*='activity%5Boutcome%5D=blocked']", minimum: 1

    get_flow("team-activity", "empty")
    assert_select "#gallery-team-activity-empty[data-nk='empty-state']", text: /No team activity matches/

    get_flow("team-activity", "error")
    assert_select "#gallery-team-activity-error[data-variant='error']"
    assert_select "#gallery-team-activity-empty", text: /temporarily unavailable/

    get_flow("team-activity", "dense")
    assert_select "#gallery-team-activity-table tbody tr", count: 18

    get_flow("team-activity", "mobile")
    assert_select "#gallery-team-activity-table thead th", count: 3
  end

  test "team member detail covers lifecycle activity policy and missing records" do
    get_flow("team-member", "active")
    assert_select "#gallery-team-member-summary[data-nk='card']", text: /Grace Hopper/
    assert_select "#gallery-team-member-stats [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-team-member-activity-table tbody tr", count: 1
    assert_select "#gallery-team-member-identity [data-variant='destructive'][href='#remove-member']"

    get_flow("team-member", "invited")
    assert_select "#gallery-team-member-status[data-color='info']", text: "Invited"
    assert_select "#gallery-team-member-activity-empty", text: /Activity begins after/

    get_flow("team-member", "suspended")
    assert_select "#gallery-team-member-status[data-color='danger']", text: "Suspended"
    assert_select "#gallery-team-member-identity [data-nk='button'][aria-disabled='true']:not([href])", count: 2

    get_flow("team-member", "activity")
    assert_select "#gallery-team-member-activity-table tbody tr", count: 2

    get_flow("team-member", "empty")
    assert_select "#gallery-team-member-error", text: /Member not found/
    assert_select "#gallery-team-member-empty", text: /No member matches/

    get_flow("team-member", "error")
    assert_select "#gallery-team-member-error", text: /lookup failed/
  end

  test "resource overview preserves filters bulk selection failure recovery and pressure" do
    get_flow("data-resource-overview", "search")
    assert_select "#resources_query[value='production']"
    assert_select "#gallery-data-resource-overview-table tbody tr", count: 1

    get_flow("data-resource-overview", "filtered")
    assert_select "#resources_status option[value='healthy'][selected]"
    assert_select "#resources_kind option[value='dataset'][selected]"
    assert_select "#gallery-data-resource-overview-table tbody tr", count: 2
    assert_select "#gallery-data-resource-overview-pagination a[href*='resources%5Bstatus%5D=healthy']", minimum: 1
    assert_select "#gallery-data-resource-overview-pagination a[href*='resources%5Bkind%5D=dataset']", minimum: 1

    get_flow("data-resource-overview", "bulk")
    assert_select "#gallery-data-resource-overview-bulk-selection[data-nk='checkbox-group']" do
      assert_select "input[type='checkbox'][name='bulk_resources[resource_ids][]']", count: 6
      assert_select "input[type='checkbox'][checked]", count: 2
      assert_select "input[type='checkbox'][disabled]", count: 1
    end
    assert_select "#gallery-data-resource-overview-bulk-submit:not([disabled])"

    get_flow("data-resource-overview", "empty")
    assert_select "#gallery-data-resource-overview-empty", text: /No resources match/

    get_flow("data-resource-overview", "error")
    assert_select "#gallery-data-resource-overview-error[data-variant='error']"
    assert_select "#gallery-data-resource-overview-empty", text: /catalog is unavailable/

    get_flow("data-resource-overview", "dense")
    assert_select "#gallery-data-resource-overview-table tbody tr", count: 18

    get_flow("data-resource-overview", "mobile")
    assert_select "#gallery-data-resource-overview-table thead th", count: 3
  end

  test "resource activity combines resource outcome query pagination and availability" do
    get_flow("data-resource-activity", "filtered")
    assert_select "#activity_query[value='replication']"
    assert_select "#activity_resource_id option[value='res_audit'][selected]"
    assert_select "#activity_outcome option[value='warning'][selected]"
    assert_select "#gallery-data-resource-activity-table tbody tr", count: 1
    assert_select "#gallery-data-resource-activity-pagination a[href*='activity%5Bresource_id%5D=res_audit']", minimum: 1

    get_flow("data-resource-activity", "empty")
    assert_select "#gallery-data-resource-activity-empty", text: /No resource activity matches/

    get_flow("data-resource-activity", "error")
    assert_select "#gallery-data-resource-activity-error[data-variant='error']"
    assert_select "#gallery-data-resource-activity-empty", text: /temporarily unavailable/

    get_flow("data-resource-activity", "dense")
    assert_select "#gallery-data-resource-activity-table tbody tr", count: 24

    get_flow("data-resource-activity", "mobile")
    assert_select "#gallery-data-resource-activity-table thead th", count: 3
  end

  test "resource settings expose validation access policy and explicit archival confirmation" do
    get_flow("data-resource-settings", "general")
    assert_select "#gallery-data-resource-settings-layout[data-nk='settings-layout']"
    assert_select "#resource_name[value='Customer accounts'][required]"
    assert_select "#resource_retention_days option[value='365'][selected]"
    assert_select "#resource_notify_failures[role='switch'][checked]"

    get_flow("data-resource-settings", "validation")
    assert_select "#gallery-data-resource-settings-validation[data-variant='error']", text: /Name/
    assert_select "#resource_name[aria-invalid='true'][value='']"

    get_flow("data-resource-settings", "success")
    assert_select "#gallery-data-resource-settings-success[data-variant='success']"

    get_flow("data-resource-settings", "error")
    assert_select "#gallery-data-resource-settings-policy[data-variant='warning']"
    assert_select "#gallery-data-resource-settings-fieldset[disabled]"
    assert_select "#gallery-data-resource-settings-submit[disabled]"

    get_flow("data-resource-settings", "access")
    assert_select "#gallery-data-resource-settings-access-table tbody tr", count: 4
    assert_select "#gallery-data-resource-settings-access-table tbody tr", text: /OwnerYesYesYes/

    get_flow("data-resource-settings", "danger")
    assert_select "#gallery-data-resource-settings-danger[data-nk='danger-zone']" do
      assert_select "> [data-slot='danger-zone-confirmation'] #gallery-data-resource-settings-danger-form"
      assert_select "> [data-slot='danger-zone-escape'][data-variant='ghost']"
    end
    assert_select "#archive_resource_confirmed[type='checkbox'][required]"
    assert_select "#gallery-data-resource-settings-danger-submit[data-variant='destructive']:not([disabled])"
  end

  private

  def get_flow(slug, state, theme: nil)
    get gallery_flow_path(slug:, state:, theme:)
    assert_response :success
  end

  def flow_title(slug)
    FLOW_TITLES.fetch(slug)
  end

  FLOW_TITLES = {
    "organization-overview" => "Organization overview",
    "organization-settings" => "Organization settings",
    "team-activity" => "Team activity",
    "team-member" => "Team member",
    "data-resource-overview" => "Data resource overview",
    "data-resource-activity" => "Data resource activity",
    "data-resource-settings" => "Data resource settings"
  }.freeze

  def assert_labelled_controls
    document = Nokogiri::HTML(response.body)
    document.css(
      "[data-gallery='flow-surface'] input:not([type='hidden'])[id], " \
        "[data-gallery='flow-surface'] select[id], " \
        "[data-gallery='flow-surface'] textarea[id]"
    ).each do |control|
      assert document.at_css("label[for='#{control['id']}']"), "missing label for #{control['id']}"
    end
  end
end
