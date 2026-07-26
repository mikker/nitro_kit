require "test_helper"

class GalleryRansackSortTest < ActiveSupport::TestCase
  test "adapts current Ransack state to Table sort values" do
    search = Gallery::CatalogItem.ransack(s: "owner desc")
    adapter = Gallery::RansackSort.new(
      search,
      path: "/gallery/components/table",
      filters: { "status_eq" => "active" }
    )

    assert_equal "owner", adapter.current
    assert_equal :desc, adapter.direction
    assert_equal({ "status_eq" => "active", "s" => "owner desc" }, adapter.parameters)
  end

  test "preserves filters and toggles only the active key" do
    search = Gallery::CatalogItem.ransack(s: "name asc")
    adapter = Gallery::RansackSort.new(
      search,
      path: "/gallery/components/table",
      filters: { name_or_owner_cont: "atlas", status_eq: "active" }
    )

    active_query = Rack::Utils.parse_nested_query(URI(adapter.href_for(:name)).query)
    other_query = Rack::Utils.parse_nested_query(URI(adapter.href_for(:seats)).query)

    assert_equal "name desc", active_query.dig("q", "s")
    assert_equal "seats asc", other_query.dig("q", "s")
    assert_equal "atlas", other_query.dig("q", "name_or_owner_cont")
    assert_equal "active", other_query.dig("q", "status_eq")
  end

  test "validates adapter boundaries" do
    assert_raises(ArgumentError) { Gallery::RansackSort.new(Object.new, path: "/records") }

    search = Gallery::CatalogItem.ransack(s: "name asc")
    assert_raises(ArgumentError) { Gallery::RansackSort.new(search, path: " ") }
    assert_raises(ArgumentError) do
      Gallery::RansackSort.new(search, path: "/records").href_for(" ")
    end
    assert_raises(ArgumentError) do
      Gallery::RansackSort.new(search, path: "/records").href_for(:" ")
    end
  end

  test "starts a new sort when the Ransack search is unsorted" do
    adapter = Gallery::RansackSort.new(
      Gallery::CatalogItem.ransack,
      path: "/gallery/components/table",
      filters: { status_eq: "trial" }
    )

    assert_nil adapter.current
    assert_nil adapter.direction
    assert_equal({ "status_eq" => "trial" }, adapter.parameters)

    query = Rack::Utils.parse_nested_query(URI(adapter.href_for(:name)).query)
    assert_equal "name asc", query.dig("q", "s")
  end
end
