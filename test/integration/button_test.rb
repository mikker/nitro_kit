require "test_helper"

class ButtonTest < ActionDispatch::IntegrationTest
  test "buttons render links and forms" do
    get test_path("button")
    assert_response :success

    assert_select "#default-button", text: "Default"
    assert_select "#primary-button", text: "Primary"
    assert_select "a#home-link[href='/']", text: "Home"
    assert_select "form[action='/signout'] button#signout-button[type='submit']", text: "Sign out"
  end
end
