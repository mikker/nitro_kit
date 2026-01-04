require "test_helper"

class TableTest < ActionDispatch::IntegrationTest
  test "table helpers render header and body cells" do
    get test_path("table")
    assert_response :success

    assert_select "table#stats-table"
    assert_select "#stats-table thead th", text: "Name"
    assert_select "#stats-table thead th.text-right", text: "Score"
    assert_select "#stats-table tbody td", text: "Alice"
    assert_select "#stats-table tbody td.text-right", text: "10"
  end
end
