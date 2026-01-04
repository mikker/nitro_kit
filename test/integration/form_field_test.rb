require "test_helper"

class FormFieldTest < ActionDispatch::IntegrationTest
  test "field helper renders label description errors and controls" do
    get test_path("form_field")
    assert_response :success

    assert_select "#email-field [data-slot='label']", text: "Email"
    assert_select "#email-field input#email[name='email'][type='email']"
    assert_select "#email-field [data-slot='description']", text: "We will never spam"
    assert_select "#email-field [data-slot='error'] li", text: "Invalid email"

    assert_select "input#birthday[type='text'][data-controller='nk--datepicker'][name='birthday']"

    assert_select "div[data-controller='nk--combobox']"
    assert_select "input[name='game-id'][type='text'][aria-controls='game-combobox-listbox']"
    assert_select "ul#game-combobox-listbox[role='listbox']"
    assert_select "input[type='hidden'][name='game-id'][value='2']"
  end
end
