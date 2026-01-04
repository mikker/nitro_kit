require "test_helper"

class TooltipTest < ActionDispatch::IntegrationTest
  test "tooltip renders content and trigger" do
    get test_path("tooltip")
    assert_response :success

    assert_select "#help-tooltip[data-controller='nk--tooltip'][data-action]"
    assert_select "#help-tooltip [data-nk--tooltip-target='content']", text: "Fill the tank"
    assert_select "#tooltip-button", text: "Hover"
  end
end
