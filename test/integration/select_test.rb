require "test_helper"

class SelectTest < ActionDispatch::IntegrationTest
  test("form builder select matches Rails API") do
    get test_path("form_builder_select")
    assert_response :success

    # Check that select element is rendered
    assert_select "select[name='user[status]']"

    # Check options are rendered correctly
    assert_select "option[value='active']", text: "Active"
    assert_select "option[value='inactive']", text: "Inactive"

    # Check selected value
    assert_select "option[value='active'][selected]"
  end

  test("select with include_blank") do
    get test_path("form_builder_select_with_blank")
    assert_response :success

    # Check blank option is first
    assert_select "option:first-child[value='']"
    # blank + 2 options
    assert_select "select option", count: 3
  end

  test("select with prompt") do
    get test_path("form_builder_select_with_prompt")
    assert_response :success

    # Check prompt option
    assert_select "option[value='']", text: "Choose status..."
  end

  test("field with as: :select") do
    get test_path("field_select")
    assert_response :success

    # Check that select element is rendered
    assert_select "select[name='user[status]']"

    # Check options are rendered correctly
    assert_select "option[value='active']", text: "Active"
    assert_select "option[value='inactive']", text: "Inactive"

    # Check selected value
    assert_select "option[value='active'][selected]"
  end

  test("field select with prompt") do
    get test_path("field_select_with_prompt")
    assert_response :success

    # Check prompt option
    assert_select "option[value='']", text: "Pick one..."
  end

  test("nk_select helper") do
    get test_path("nk_select_helper")
    assert_response :success

    # Check that select element is rendered with correct name
    assert_select "select[name='journey[direction]']"

    # Check options are rendered correctly
    assert_select "option[value='North']", text: "North"
    assert_select "option[value='East']", text: "East"
    assert_select "option[value='South']", text: "South"
    assert_select "option[value='West']", text: "West"

    # Check selected value
    assert_select "option[value='South'][selected]"
  end
end
