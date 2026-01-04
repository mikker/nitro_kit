require "test_helper"

class TabsTest < ActionDispatch::IntegrationTest
  test "tabs render with aria state and panels" do
    get test_path("tabs")
    assert_response :success

    assert_select "#settings-tabs[data-controller='nk--tabs']"
    assert_select "#settings-tabs [role='tab'][aria-selected='true']", text: "General"
    assert_select "#settings-tabs [role='tab'][aria-selected='false']", text: "Billing"
    assert_select "#settings-tabs [role='tabpanel'][aria-hidden='false']", text: "General content"
    assert_select "#settings-tabs [role='tabpanel'][aria-hidden='true']", text: "Billing content"
  end
end
