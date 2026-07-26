require "test_helper"

class Gallery::CatalogTest < ActiveSupport::TestCase
  test "catalog starts with home and exposes one nested navigation tree" do
    assert_equal "home", Gallery::Catalog.home.slug
    assert_equal Gallery::Home, Gallery::Catalog.home.page
    assert_equal %i[component block flow], Gallery::Catalog.collections.map(&:kind)
    assert_equal [ "all" ], Gallery::Catalog.collection!(:component).categories.map(&:slug)
    assert_nil Gallery::Catalog.collection!(:component).categories.first.title
    assert_equal %w[shells navigation sections], Gallery::Catalog.collection!(:block).categories.map(&:slug)
    assert_equal %w[
      access-and-onboarding workspace-and-organization billing-and-commerce data-and-operations
      product-and-support marketing complete-applications
    ], Gallery::Catalog.collection!(:flow).categories.map(&:slug)
    assert_equal(
      %w[
        accordion alert appearance-picker app-navigation avatar avatar-stack badge button button-group card checkbox checkbox-group
        combobox container details-table dialog dropdown dropzone field field-group fieldset flex grid icon input label
        pagination progressive-image radio-button radio-button-group rich-text-area select switch table tabs textarea
        toast tooltip
        typeset
      ],
      Gallery::Catalog.entries(kind: :component).map(&:slug)
    )
    assert_equal(
      %w[
        auth-shell app-shell settings-layout toolbar pagination-bar page-header stat-grid data-section form-section danger-zone
        empty-state
      ],
      Gallery::Catalog.entries(kind: :block).map(&:slug)
    )
    assert_equal(
      %w[
        sign-in password-reset email-verification invitation-acceptance account-creation account-security onboarding
        onboarding-branches dashboard settings users team-management api-credentials organization-overview organization-settings
        team-activity team-member billing checkout checkout-result data-resource-overview data-resource-activity
        data-resource-settings api-webhooks integration-management uploads activity-audit changelog help-center system-status
        landing pricing features contact application-sidebar application-topbar application-hybrid
      ],
      Gallery::Catalog.entries(kind: :flow).map(&:slug)
    )
  end

  test "collections partition every entry once and reject typo category names" do
    nested_entries = Gallery::Catalog.collections.flat_map(&:entries)

    assert_equal Gallery::Catalog.entries.drop(1), nested_entries
    assert_equal nested_entries.uniq, nested_entries
    assert_equal "Sections", Gallery::Catalog.category!(kind: :block, slug: "sections").title
    landing = Gallery::Catalog.fetch!(kind: :flow, slug: "landing")
    assert_equal "Marketing", Gallery::Catalog.category_for(landing).title
    assert_raises(Gallery::Catalog::CategoryNotFound) do
      Gallery::Catalog.category!(kind: :flow, slug: "marketng")
    end
    assert_raises(Gallery::Catalog::CollectionNotFound) do
      Gallery::Catalog.collection!(:section)
    end
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

  test "flow entries declare deterministic states or one complete application showcase" do
    Gallery::Catalog.entries(kind: :flow).each do |flow|
      assert flow.page < Gallery::Page
      if flow.page < Gallery::Flows::ApplicationPage
        assert_empty flow.states
      else
        assert_predicate flow.states, :any?
      end
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

  test "every component and block entry finds its shipped contract row" do
    entries = Gallery::Catalog.entries(kind: :component) + Gallery::Catalog.entries(kind: :block)

    missing = entries.reject do |candidate|
      Gallery::Contracts.rows.key?(Gallery::Contracts.component_name_for(candidate))
    end

    assert_empty missing.map(&:slug)
    entries.each do |candidate|
      row = Gallery::Contracts.for_entry(candidate)

      assert_equal Gallery::Contracts.component_name_for(candidate), row.component
      assert_predicate row.fields, :any?
    end
    assert_raises(Gallery::Contracts::ContractNotFound) { Gallery::Contracts.fetch!("Nonexistent") }
  end

  test "declared page patterns resolve to summarized pattern documents" do
    assert_equal(
      Gallery::Catalog::PATTERNS.keys.uniq,
      Gallery::Catalog::PATTERNS.keys,
      "duplicate pattern declarations"
    )

    Gallery::Catalog::PATTERNS.each_key do |kind, slug|
      entry = Gallery::Catalog.fetch!(kind:, slug:)
      patterns = Gallery::Catalog.patterns_for(entry)

      assert_predicate patterns, :any?
      patterns.each do |pattern|
        assert_predicate pattern.title, :present?
        assert_includes 3..6, pattern.points.size, "#{pattern.slug} summary"
      end
    end

    assert_empty Gallery::Catalog.patterns_for(Gallery::Catalog.fetch!(kind: :component, slug: "button"))
    assert_equal(
      Gallery::Patterns.slugs.sort,
      Gallery::Catalog::PATTERNS.values.flatten.uniq.sort,
      "every pattern document should be reachable from at least one page"
    )
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
      description: nil,
      page: Gallery::Home,
      states:,
      expected_roots: []
    )
  end
end
