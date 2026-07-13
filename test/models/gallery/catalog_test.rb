require "test_helper"

class Gallery::CatalogTest < ActiveSupport::TestCase
  test "catalog starts with an explicit home entry and grouped component pages" do
    assert_equal "home", Gallery::Catalog.home.slug
    assert_equal Gallery::Home, Gallery::Catalog.home.page
    assert_equal %i[component block flow], Gallery::Catalog.navigation_groups.map(&:kind)
    assert_equal(
      %w[
        button icon button-group pagination card input field label textarea select checkbox checkbox-group radio-button
        radio-button-group switch field-group fieldset table dialog dropdown tooltip combobox datepicker toast alert avatar
        avatar-stack badge accordion tabs v-stack h-stack grid container
      ],
      Gallery::Catalog.entries(kind: :component).map(&:slug)
    )
    assert_equal(
      %w[
        auth-shell settings-layout toolbar pagination-bar page-header stat-grid data-section form-section danger-zone
        empty-state
      ],
      Gallery::Catalog.entries(kind: :block).map(&:slug)
    )
    assert_equal(
      %w[
        sign-in password-reset email-verification invitation-acceptance account-creation onboarding dashboard settings
        billing users team-management api-credentials organization-overview organization-settings team-activity team-member
        data-resource-overview data-resource-activity data-resource-settings checkout account-security onboarding-branches
        api-webhooks integration-management uploads activity-audit changelog help-center system-status landing pricing features
        contact checkout-result
      ],
      Gallery::Catalog.entries(kind: :flow).map(&:slug)
    )
  end

  test "component entries declare their route contract explicitly" do
    Gallery::Catalog.entries(kind: :component).each do |component|
      assert component.page < Gallery::ComponentPage
      assert_predicate component.expected_roots, :any?
      assert component.expected_roots.all? { |root| root.match?(/\A[a-z0-9-]+\z/) }
    end
  end

  test "block entries declare their route contract explicitly" do
    Gallery::Catalog.entries(kind: :block).each do |block|
      assert block.page < Gallery::ComponentPage
      assert_empty block.states
      assert_predicate block.expected_roots, :any?
      assert block.expected_roots.all? { |root| root.match?(/\A[a-z0-9-]+\z/) }
    end
  end

  test "flow entries declare deterministic states and page contracts" do
    Gallery::Catalog.entries(kind: :flow).each do |flow|
      assert flow.page < Gallery::Page
      assert_predicate flow.states, :any?
      assert_equal flow.states.uniq, flow.states
      assert flow.states.all? { |state| state.match?(/\A[a-z0-9-]+\z/) }
      assert_predicate flow.expected_roots, :any?
    end
  end

  test "catalog resolves stable paths for each entry kind" do
    routes = Rails.application.routes.url_helpers

    assert_equal "/gallery", Gallery::Catalog.path_for(Gallery::Catalog.home, routes:)
    assert_equal "/gallery/components/button", Gallery::Catalog.path_for(entry(:component, "button"), routes:)
    assert_equal "/gallery/blocks/page-header", Gallery::Catalog.path_for(entry(:block, "page-header"), routes:)
    assert_equal(
      "/gallery/flows/dashboard/active",
      Gallery::Catalog.path_for(entry(:flow, "dashboard", states: [ "active" ]), routes:)
    )
  end

  test "catalog validates flow states" do
    dashboard = entry(:flow, "dashboard", states: %w[new active degraded])

    assert_equal "new", Gallery::Catalog.resolve_state!(dashboard, nil)
    assert_equal "active", Gallery::Catalog.resolve_state!(dashboard, "active")
    assert_raises(Gallery::Catalog::StateNotFound) do
      Gallery::Catalog.resolve_state!(dashboard, "missing")
    end
  end

  test "catalog rejects unknown entries" do
    assert_raises(Gallery::Catalog::EntryNotFound) do
      Gallery::Catalog.fetch!(kind: :component, slug: "missing")
    end
  end

  private

  def entry(kind, slug, states: [])
    Gallery::Catalog::Entry.new(
      kind:,
      slug:,
      title: slug.humanize,
      group: kind.to_s.humanize,
      description: nil,
      page: Gallery::Home,
      states:,
      expected_roots: []
    )
  end
end
