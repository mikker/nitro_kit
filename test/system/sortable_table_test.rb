require "application_system_test_case"

class SortableTableSystemTest < ApplicationSystemTestCase
  setup do
    Gallery::CatalogItem.delete_all
    Gallery::CatalogItem.seed_examples!
  end

  test "Ransack recipe filters sorts paginates and recovers from empty results in its Turbo frame" do
    path = gallery_component_path("sortable-table")
    visit path

    within("#gallery-sortable-table-results") do
      assert_selector "[data-gallery-catalog-row]", count: 5
      assert_selector "th[data-sort-key='name'][aria-sort='ascending']"

      within("th[data-sort-key='seats']") { click_link("Seats") }
      assert_selector "th[data-sort-key='seats'][aria-sort='ascending']"
      within("th[data-sort-key='seats']") { click_link("Seats") }
      assert_selector "th[data-sort-key='seats'][aria-sort='descending']"

      fill_in "Search workspaces", with: "Atlas"
      select "Active", from: "Status"
      click_button "Apply filters"
      assert_selector "[data-gallery-catalog-row]", count: 1
      assert_text "Atlas Workspace"

      fill_in "Search workspaces", with: "no-such-workspace"
      select "All statuses", from: "Status"
      click_button "Apply filters"
      assert_selector "td[colspan='6']", text: "No workspaces match these filters"

      click_link "Reset"
      assert_selector "[data-gallery-catalog-row]", count: 5
      within("#gallery-sortable-table-pagination") { click_link("2") }
      assert_selector "[aria-current='page']", text: "2"
      assert_text "Showing 6–10 of 15 workspaces"
    end

    assert_no_severe_console_errors(context: path)
  end
end
