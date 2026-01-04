require "test_helper"

class CheckboxRadioTest < ActionDispatch::IntegrationTest
  test "checkboxes and radio groups render inputs and labels" do
    get test_path("checkbox_radio")
    assert_response :success

    assert_select "input#terms[type='checkbox']"
    assert_select "label[for='terms']", text: "Accept terms"

    assert_select "input#features-fast[type='checkbox'][checked]"

    assert_select "#size-group input[type='radio'][value='lg'][checked]"
    assert_select "#size-group input[type='radio'][value='sm']"
  end
end
