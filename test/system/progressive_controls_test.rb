require "application_system_test_case"

class ProgressiveControlsTest < ApplicationSystemTestCase
  test "checkable controls reflect native state and restore indeterminate state after value changes" do
    path = gallery_component_path("checkbox")
    visit path

    control = "#gallery-checkbox-indeterminate-control"
    root = "#gallery-checkbox-indeterminate"
    assert evaluate_script("document.querySelector(arguments[0]).indeterminate", control)

    execute_script("document.querySelector(arguments[0]).click()", control)
    assert_selector "#{root}:not([data-state])"
    refute evaluate_script("document.querySelector(arguments[0]).indeterminate", control)
    assert_nil find(control, visible: :all)["aria-checked"]

    execute_script(<<~JAVASCRIPT, root)
      document.querySelector(arguments[0]).setAttribute(
        "data-nk--checkable-indeterminate-value",
        "true"
      );
    JAVASCRIPT
    assert_selector "#{root}[data-state='indeterminate']"
    assert evaluate_script("document.querySelector(arguments[0]).indeterminate", control)

    visit gallery_component_path("radio-button")
    execute_script("document.querySelector('#gallery-radio-button-organization-control').click()")
    assert_selector "#gallery-radio-button-private input:not(:checked)", visible: :all
    assert_selector "#gallery-radio-button-organization input:checked", visible: :all
    assert_selector "#gallery-radio-button-organization:not([data-controller])"

    visit gallery_component_path("switch")
    switch = find("#gallery-switch-medium-control", visible: :all)
    assert_equal "Weekly digest", switch.native.accessible_name
    assert_equal "gallery-switch-medium-control-description", switch["aria-describedby"]
    execute_script("document.querySelector('#gallery-switch-medium-control').click()")
    assert_selector "#gallery-switch-medium input:checked", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "tabs reveal every panel when enhancement disconnects and restore APG state on reconnect" do
    path = gallery_component_path("tabs")
    visit path
    root = "#gallery-tabs-settings"

    assert_selector "#{root}[data-enhanced='true']"
    assert_selector "#{root} [data-slot='tabs-panel'][hidden]", count: 2, visible: :all
    assert_selector "#{root} [data-slot='tabs-panel']:not([hidden])", count: 1

    execute_script("document.querySelector(arguments[0]).removeAttribute('data-controller')", root)

    assert_no_selector "#{root}[data-enhanced]", visible: :all
    assert_selector "#{root} [data-slot='tabs-panel']:not([hidden])", count: 3
    assert_selector "#{root} [data-slot='tabs-panel']:not([aria-hidden])", count: 3
    assert_selector "#{root} [data-slot='tabs-tab'][tabindex='0']", count: 3

    execute_script("document.querySelector(arguments[0]).setAttribute('data-controller', 'nk--tabs')", root)

    assert_selector "#{root}[data-enhanced='true']"
    assert_selector "#{root} [data-slot='tabs-panel'][hidden]", count: 2, visible: :all
    find("#{root} [data-slot='tabs-tab']", text: "Billing").click
    assert_selector "#{root} [data-slot='tabs-tab'][aria-selected='true']", text: "Billing"
    assert_selector "#{root} [data-key='billing'][data-slot='tabs-panel']:not([hidden])", text: /Review plan/
    assert_no_severe_console_errors(context: path)
  end

  test "combobox enhances one native submission value and restores its fallback on disconnect" do
    path = gallery_component_path("combobox")
    visit path
    root = "#gallery-combobox-environment"
    input = "#gallery-combobox-environment-input"
    select = "#gallery-combobox-environment-value"

    assert_selector "#{root}[data-enhanced='true']"
    assert_selector "#{root} [data-slot='combobox-native'][hidden]", visible: :all
    assert_selector "#{root} [data-slot='combobox-control']:not([hidden])"
    assert_equal 1, all("#{root} [name='deployment[environment]']", visible: :all).size
    assert_equal "", find(input)["name"]

    find(input).set("No matching environment")
    assert_selector "#{root} [data-slot='combobox-status']", text: "No options found.", visible: :all

    find(input).set("Staging")
    assert_selector "#{root} [data-slot='combobox-status']", text: "1 option available.", visible: :all
    find("#{root} [data-slot='combobox-option']", text: "Staging").click

    assert_equal "staging", find(select, visible: :all).value
    assert_equal [ "staging" ], evaluate_script(<<~JAVASCRIPT)
      Array.from(new FormData(document.querySelector("#gallery-combobox-deployment-form")).getAll("deployment[environment]"));
    JAVASCRIPT

    execute_script(<<~JAVASCRIPT, root)
      const native = document.querySelector(arguments[0]).querySelector('[data-slot="combobox-native"]');
      native.replaceWith(native.cloneNode(true));
    JAVASCRIPT
    assert_selector "#{root} [data-slot='combobox-native'][hidden]", visible: :all
    refute evaluate_script("document.querySelector(arguments[0]).required", select)

    execute_script("document.querySelector(arguments[0]).removeAttribute('data-controller')", root)

    assert_no_selector "#{root}[data-enhanced]", visible: :all
    assert_selector "#{root} [data-slot='combobox-native']:not([hidden])"
    assert_selector "#{root} [data-slot='combobox-control'][hidden]", visible: :all
    assert evaluate_script("document.querySelector(arguments[0]).required", select)
    assert_no_severe_console_errors(context: path)
  end

  test "failed progressive images retain informative alt text" do
    path = gallery_component_path("progressive-image")
    visit path
    root = "#gallery-progressive-image-error"

    assert_selector "#{root}[data-state='error']"
    image = find("#{root} [data-slot='progressive-image-image']", visible: :all)
    assert_equal "Unavailable workspace cover", image["alt"]
    assert_nil image["aria-hidden"]
    assert_selector "#{root} [data-slot='progressive-image-fallback']", text: "Unavailable workspace cover"
    assert_no_severe_console_errors(context: path)
  end
end
