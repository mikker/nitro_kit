require "test_helper"

class GalleryNavigationComponentsTest < ActionDispatch::IntegrationTest
  SLUGS = %w[settings-layout toolbar pagination-bar].freeze

  test "catalog groups the accepted navigation components and defers progress steps" do
    entries = SLUGS.map { |slug| Gallery::Catalog.fetch!(kind: :component, slug:) }

    assert_equal SLUGS, entries.map(&:slug)
    assert_equal %i[layout navigation navigation], entries.map(&:subcategory)
    assert_equal(
      SLUGS.map { |slug| "/gallery/components/#{slug}" },
      entries.map { |entry| Gallery::Catalog.path_for(entry, routes: Rails.application.routes.url_helpers) }
    )
    assert_empty Gallery::Catalog.entries(kind: :component).map(&:slug) & %w[progress-steps]
  end

  test "every navigation component page is direct class-free Phlex in light and dark themes" do
    SLUGS.each do |slug|
      %w[light dark].each do |theme|
        get gallery_component_path(slug, theme:)

        assert_response :success
        assert_select "html[data-theme='#{theme}']"
        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}']"
        assert_select "[data-gallery='example-canvas'] [data-nk='#{slug}'][id]", minimum: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
      end
    end
  end

  test "settings layout page covers required regions cardinality long pressure and nested blocks" do
    get_block("settings-layout")

    assert_select "[data-gallery='example-canvas'] [data-nk='settings-layout']", minimum: 1 do |layouts|
      layouts.each do |layout|
        assert_equal 1, layout.xpath("./*[@data-slot='settings-layout-navigation']").count
        assert_equal 1, layout.xpath("./*[@data-slot='settings-layout-content']").count
        assert_equal "nav", layout.xpath("./*[@data-slot='settings-layout-navigation']").first.name
        assert_predicate layout.xpath("./*[@data-slot='settings-layout-navigation']").first["aria-label"], :present?
      end
    end
    assert_select "#gallery-settings-layout-one [data-slot='settings-layout-item']", count: 1
    assert_select "#gallery-settings-layout-workspace > nav[data-slot='settings-layout-navigation']" do
      assert_select "ul[data-slot='settings-layout-items'] > li[data-slot='settings-layout-item']", count: 4
      assert_select "a[data-slot='settings-layout-item-link'][aria-current='page'][data-state='current']", count: 1
      assert_select "a[data-slot='settings-layout-item-link'][data-state='default']", count: 3
      assert_select "[data-nk='button']", count: 0
    end
    assert_select "#gallery-settings-layout-many [data-nk='card']", count: 6
    assert_select "#gallery-settings-layout-long > nav[aria-label*='International Research and Production settings']"
    assert_select "#gallery-settings-layout-audit > [data-slot='settings-layout-content']" do
      assert_select "[data-nk='toolbar']", count: 1
      assert_select "[data-nk='pagination-bar']", count: 1
      assert_select "[data-nk='pagination']", count: 1
    end
  end

  test "toolbar page covers every valid region shape wrapping dense and real compositions" do
    get_block("toolbar")

    assert_select "[data-gallery='example-canvas'] [data-nk='toolbar']", minimum: 1 do |toolbars|
      toolbars.each do |toolbar|
        assert_operator toolbar.xpath("./*[@data-slot='toolbar-leading']").count, :<=, 1
        assert_operator toolbar.xpath("./*[@data-slot='toolbar-trailing']").count, :<=, 1
        assert_operator toolbar.element_children.count, :>=, 1
        assert_nil toolbar["role"]
      end
    end
    assert_select "#gallery-toolbar-leading-only > [data-slot='toolbar-leading']", count: 1
    assert_select "#gallery-toolbar-leading-only > [data-slot='toolbar-trailing']", count: 0
    assert_select "#gallery-toolbar-trailing-only > [data-slot='toolbar-leading']", count: 0
    assert_select "#gallery-toolbar-trailing-only > [data-slot='toolbar-trailing']", count: 1
    assert_select "#gallery-toolbar-split > [data-slot]", count: 2
    assert_select "#gallery-toolbar-long [data-nk='button']", count: 3
    assert_select "#gallery-toolbar-dense [data-nk='badge']", count: 8
    assert_select "#gallery-toolbar-dense [data-nk='button']", count: 5
    assert_select "#gallery-toolbar-collection-create[data-variant='primary']"
    assert_select "#gallery-toolbar-form > [data-slot='toolbar-trailing'] [data-nk='button']", count: 2
  end

  test "pagination bar page covers optional summaries boundaries query pressure and dense navigation" do
    get_block("pagination-bar")

    assert_select "[data-gallery='example-canvas'] [data-nk='pagination-bar']", minimum: 1 do |bars|
      bars.each do |bar|
        assert_operator bar.xpath("./*[@data-slot='pagination-bar-summary']").count, :<=, 1
        assert_equal 1, bar.xpath("./*[@data-nk='pagination'][@data-slot='pagination-bar-pagination']").count
      end
    end
    assert_select "#gallery-pagination-bar-first-page-1[aria-current='page']"
    assert_select "#gallery-pagination-bar-first-previous[aria-disabled='true']:not([href])"
    assert_select "#gallery-pagination-bar-middle-page-6[aria-current='page']"
    assert_select "#gallery-pagination-bar-final-page-12[aria-current='page']"
    assert_select "#gallery-pagination-bar-final-next[aria-disabled='true']:not([href])"
    assert_select "#gallery-pagination-bar-no-summary > [data-slot='pagination-bar-summary']", count: 0
    assert_select "#gallery-pagination-bar-rich-summary > [data-slot='pagination-bar-summary'] [data-nk='badge']", count: 1
    assert_select "#gallery-pagination-bar-filtered-summary[aria-live='polite']", text: /international research/
    assert_select "#gallery-pagination-bar-filtered a[href*='query=research'][href*='status=active']", minimum: 1
    assert_select "#gallery-pagination-bar-dense [data-slot='pagination-item'][data-kind='page']", count: 12
    assert_select "#gallery-pagination-bar-invoices-table tbody tr", count: Gallery::Data.invoices.size
  end

  test "real settings states use the layout with toolbars only around form and collection actions" do
    %w[profile security notifications integrations appearance].each do |state|
      get gallery_composition_path(slug: "settings", state:)

      assert_response :success
      assert_select "#gallery-settings-layout[data-nk='settings-layout']" do
        assert_select "> nav[data-slot='settings-layout-navigation'][aria-label='Settings sections']", count: 1
        assert_select "> [data-slot='settings-layout-content']", count: 1
      end
      assert_select "#gallery-settings-layout [data-slot='settings-layout-content'] [data-nk='toolbar']", minimum: 1
    end

    get gallery_composition_path(slug: "settings", state: "integrations-empty")

    assert_response :success
    assert_select "#gallery-settings-layout[data-nk='settings-layout']"
    assert_select "#gallery-settings-integrations-empty-section[data-nk='data-section'] > " \
                  "#gallery-settings-integrations-empty[data-nk='empty-state']",
      count: 1
    assert_select "#gallery-settings-layout [data-slot='settings-layout-content'] [data-nk='toolbar']", count: 0
  end

  test "real user and invoice collections use PaginationBar without moving route math into it" do
    [
      [ "users", "index", "gallery-users-index-pagination-bar", "gallery-users-index-pagination" ],
      [ "users", "search", "gallery-users-search-pagination-bar", "gallery-users-search-pagination" ],
      [ "billing", "invoices", "gallery-billing-invoice-pagination-bar", "gallery-billing-invoice-pagination" ]
    ].each do |slug, state, bar_id, pagination_id|
      get gallery_composition_path(slug:, state:)

      assert_response :success
      assert_select "##{bar_id}[data-nk='pagination-bar']" do
        assert_select "> [data-slot='pagination-bar-summary']", count: 1
        assert_select "> ##{pagination_id}[data-nk='pagination'][data-slot='pagination-bar-pagination']", count: 1
      end
    end

    get gallery_composition_path(slug: "users", state: "search")
    assert_equal(
      "/gallery/compositions/users/search?page=4&query=a&status=active",
      css_select("#gallery-users-search-pagination-next").first["href"]
    )
    get gallery_composition_path(slug: "billing", state: "invoices")
    assert_equal(
      "/gallery/compositions/billing/invoices?page=11",
      css_select("#gallery-billing-invoice-pagination-previous").first["href"]
    )
  end

  private

  def get_block(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
