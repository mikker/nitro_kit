require "test_helper"

class AlertCardBadgeTest < ActionDispatch::IntegrationTest
  test "alerts cards and badges render expected structure" do
    get test_path("alert_card_badge")
    assert_response :success

    assert_select "#alert-default[role='alert'] h5", text: "Heads up"
    assert_select "#alert-default[role='alert'] div", text: "Something happened"
    assert_select "#alert-success[role='alert'] h5", text: "Saved"

    assert_select "#card h2", text: "Card title"
    assert_select "#card div", text: "Card body"
    assert_select "#card [data-slot='full'] hr"

    assert_select "#badge-new", text: "New"
    assert_select "#badge-outline.border", text: "Outline"
  end
end
