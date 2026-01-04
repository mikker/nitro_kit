require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  test "pagination renders links and current state" do
    get test_path("pagination")
    assert_response :success

    assert_select "nav#pager"
    assert_select "#pager a", text: "Previous"
    assert_select "#pager a[aria-current='page']", text: "1"
    assert_select "#pager a", text: "2"
    assert_select "#pager a", text: "Next"
    assert_select "#pager button"
  end
end
