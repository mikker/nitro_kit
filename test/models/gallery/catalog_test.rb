require "test_helper"

class Gallery::CatalogTest < ActiveSupport::TestCase
  test "catalog starts with home and exposes one nested navigation tree" do
    assert_equal "home", Gallery::Catalog.home.slug
    assert_equal Gallery::Home, Gallery::Catalog.home.page
    assert_equal %i[foundation component composition], Gallery::Catalog.collections.map(&:kind)
    assert_equal %w[theme], Gallery::Catalog.collection!(:foundation).categories.map(&:slug)
    assert_equal %w[colors typography spacing-sizing effects], Gallery::Catalog.entries(kind: :foundation).map(&:slug)
    assert_equal(
      %w[actions forms overlays feedback data navigation layout application],
      Gallery::Catalog.collection!(:component).categories.map(&:slug)
    )
    assert_equal %w[
      access-and-onboarding workspace-and-organization billing-and-commerce data-and-operations
      product-and-support marketing complete-applications
    ], Gallery::Catalog.collection!(:composition).categories.map(&:slug)
    assert_equal(
      {
        "actions" => %w[button button-group button-to],
        "forms" => %w[
          appearance-picker checkbox checkbox-group combobox control-group dropzone field field-group fieldset input
          label radio-button radio-button-group rich-text-area select switch textarea
        ],
        "overlays" => %w[command-palette dialog dropdown sheet tooltip],
        "feedback" => %w[alert empty-state toast],
        "data" => %w[accordion avatar avatar-stack badge details-table icon progressive-image stat-grid table typeset],
        "navigation" => %w[pagination pagination-bar tabs toolbar],
        "layout" => %w[card container flex grid],
        "application" => %w[
          app-navigation app-shell auth-shell danger-zone data-section settings-section page-header settings-layout
        ]
      },
      Gallery::Catalog.collection!(:component).categories.to_h { |category| [ category.slug, category.entries.map(&:slug) ] }
    )
    assert_equal(
      %w[
        sign-in password-reset email-verification invitation-acceptance account-creation account-security onboarding
        onboarding-branches dashboard settings users team-management api-credentials organization-overview organization-settings
        team-activity team-member billing checkout checkout-result data-resource-overview data-resource-activity
        data-resource-settings product-resource api-webhooks integration-management uploads activity-audit changelog help-center
        system-status landing pricing features contact application-sidebar application-topbar application-hybrid
      ],
      Gallery::Catalog.entries(kind: :composition).map(&:slug)
    )
  end

  test "every component declares exactly one known subcategory" do
    known = Gallery::Catalog::SUBCATEGORIES.map(&:first)

    Gallery::Catalog.entries(kind: :component).each do |component|
      assert_includes known, component.subcategory, component.slug
    end
    assert_nil Gallery::Catalog.home.subcategory
    Gallery::Catalog.entries(kind: :foundation).each do |foundation|
      assert_nil foundation.subcategory, foundation.slug
    end
    Gallery::Catalog.entries(kind: :composition).each do |composition|
      assert_nil composition.subcategory, composition.slug
    end
  end

  test "collections partition every entry once and reject typo category names" do
    nested_entries = Gallery::Catalog.collections.flat_map(&:entries)

    assert_equal Gallery::Catalog.entries.drop(1).sort_by(&:slug), nested_entries.sort_by(&:slug)
    assert_equal nested_entries.uniq, nested_entries
    assert_equal "Forms", Gallery::Catalog.category!(kind: :component, slug: "forms").title
    assert_equal "Theme", Gallery::Catalog.category!(kind: :foundation, slug: "theme").title
    assert_equal(
      "Application",
      Gallery::Catalog.category_for(Gallery::Catalog.fetch!(kind: :component, slug: "page-header")).title
    )
    landing = Gallery::Catalog.fetch!(kind: :composition, slug: "landing")
    assert_equal "Marketing", Gallery::Catalog.category_for(landing).title
    assert_raises(Gallery::Catalog::CategoryNotFound) do
      Gallery::Catalog.category!(kind: :composition, slug: "marketng")
    end
    assert_raises(Gallery::Catalog::CollectionNotFound) do
      Gallery::Catalog.collection!(:section)
    end
  end

  test "component entries declare their route contract explicitly" do
    Gallery::Catalog.entries(kind: :component).each do |component|
      assert component.page < Gallery::ComponentPage
      assert_empty component.states
      assert_predicate component.expected_roots, :any?
      assert component.expected_roots.all? { |root| root.match?(/\A[a-z0-9-]+\z/) }
    end
  end

  test "foundation entries declare a page and stable examples" do
    Gallery::Catalog.entries(kind: :foundation).each do |foundation|
      assert foundation.page < Gallery::FoundationPage
      assert_empty foundation.states
      assert_predicate foundation.expected_roots, :any?
    end
  end

  test "composition entries declare deterministic states or one complete application showcase" do
    Gallery::Catalog.entries(kind: :composition).each do |composition|
      assert composition.page < Gallery::Page
      if composition.page < Gallery::Compositions::ApplicationPage
        assert_empty composition.states
      else
        assert_predicate composition.states, :any?
      end
      assert_equal composition.states.uniq, composition.states
      assert composition.states.all? { |state| state.match?(/\A[a-z0-9-]+\z/) }
      assert_predicate composition.expected_roots, :any?
    end
  end

  test "catalog resolves stable paths for each entry kind" do
    routes = Rails.application.routes.url_helpers

    assert_equal "/gallery", Gallery::Catalog.path_for(Gallery::Catalog.home, routes:)
    assert_equal "/gallery/foundations/colors", Gallery::Catalog.path_for(entry(:foundation, "colors"), routes:)
    assert_equal "/gallery/components/button", Gallery::Catalog.path_for(entry(:component, "button"), routes:)
    assert_equal "/gallery/components/page-header", Gallery::Catalog.path_for(entry(:component, "page-header"), routes:)
    assert_equal(
      "/gallery/compositions/dashboard/active",
      Gallery::Catalog.path_for(entry(:composition, "dashboard", states: [ "active" ]), routes:)
    )
  end

  test "catalog validates composition states" do
    dashboard = entry(:composition, "dashboard", states: %w[new active degraded])

    assert_equal "new", Gallery::Catalog.resolve_state!(dashboard, nil)
    assert_equal "active", Gallery::Catalog.resolve_state!(dashboard, "active")
    assert_raises(Gallery::Catalog::StateNotFound) do
      Gallery::Catalog.resolve_state!(dashboard, "missing")
    end
  end

  test "every component entry finds its shipped contract row" do
    entries = Gallery::Catalog.entries(kind: :component)

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

  test "data section contract is not truncated by markdown pipes" do
    contract = Gallery::Contracts.fetch!("DataSection")
    compound = contract.fields.find { |field| field.label == "Compound contract" }

    assert_includes compound.value, "DetailsTable"
    assert_includes compound.value, "EmptyState"
    assert_includes compound.value, "actions"
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
