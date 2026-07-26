require "test_helper"

class TableGalleryTest < ActionDispatch::IntegrationTest
  setup do
    Gallery::CatalogItem.delete_all
    Gallery::CatalogItem.seed_examples!
  end

  test "gallery renders sort states and executable Ransack source" do
    get gallery_component_path("table")

    assert_response :success
    assert_select "[data-gallery-page='table']"
    assert_select "[data-gallery='code-source']", text: /Gallery::CatalogItem\.ransack/
    assert_select "#gallery-table-sort-ascending th[data-sort-key='name'][aria-sort='ascending']"
    assert_select "#gallery-table-sort-descending th[data-sort-key='seats'][aria-sort='descending'][data-align='right']"
    assert_select "#gallery-table-sort-unsorted th[aria-sort='none']", count: 2
    assert_select "#gallery-table-sort-unsorted th[aria-sort='ascending']", count: 0
    assert_select "##{Gallery::Components::TablePage::FRAME_ID}"
    assert_select "#gallery-table-ransack-results [data-gallery-catalog-row]", count: 5
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end

  test "Ransack recipe filters sorts paginates and renders an empty result" do
    get gallery_component_path("table"), params: {
      q: { name_or_owner_cont: "Atlas", status_eq: "active", s: "seats desc" }
    }

    assert_response :success
    assert_select "#gallery-table-ransack-results th[data-sort-key='seats'][aria-sort='descending']"
    assert_select "#gallery-table-ransack-results [data-gallery-catalog-row]", count: 1
    assert_select "#gallery-table-ransack-results", text: /Atlas Workspace/
    assert_select "#gallery-table-pagination-bar", text: /Showing 1–1 of 1 workspaces/

    get gallery_component_path("table"), params: { q: { s: "name asc" }, page: 2 }

    assert_response :success
    assert_select "#gallery-table-ransack-results [data-gallery-catalog-row]", count: 5
    assert_select "#gallery-table-pagination [aria-current='page']", text: "2"
    assert_select "#gallery-table-pagination-bar", text: /Showing 6–10 of 15 workspaces/

    get gallery_component_path("table"), params: { q: { name_or_owner_cont: "no-such-workspace" } }

    assert_response :success
    assert_select "#gallery-table-ransack-results [data-gallery-catalog-row]", count: 0
    assert_select "#gallery-table-ransack-results td[colspan='5']", text: /No workspaces match/
    assert_select "#gallery-table-pagination-bar", text: /Showing 0–0 of 0 workspaces/
  end

  test "Ransack remains outside the gem runtime and core component" do
    root = NitroKit::Engine.root
    specification = Gem::Specification.load(root.join("nitro_kit.gemspec").to_s)
    refute_includes specification.runtime_dependencies.map(&:name), "ransack"
    refute_includes root.join("app/components/nitro_kit/table.rb").read, "Ransack"
  end
end
