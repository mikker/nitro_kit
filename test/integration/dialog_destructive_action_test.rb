require "test_helper"

class DialogDestructiveActionTest < ActionDispatch::IntegrationTest
  test "real DELETE form redirects with See Other" do
    delete gallery_destructive_action_path

    assert_response :see_other
    assert_redirected_to gallery_component_path("dialog")
  end
end
