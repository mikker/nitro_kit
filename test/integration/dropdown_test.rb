require "test_helper"

class DropdownTest < ActionDispatch::IntegrationTest
  test "dropdown renders trigger content and items" do
    get test_path("dropdown_helper")
    assert_response :success

    assert_select "#menu"
    assert_select "#menu-trigger[aria-haspopup='true'][aria-expanded='false'][data-nk--dropdown-target='trigger']"
    assert_select "#menu-content[role='menu'][aria-hidden='true'][data-nk--dropdown-target='content']"
    assert_select "#menu-content [role='menuitem'][href='/edit']", text: "Edit"
    assert_select "#menu-content [role='menuitem'][href='/delete']", text: "Delete"
  end
end
