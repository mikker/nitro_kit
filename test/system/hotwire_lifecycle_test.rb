require "application_system_test_case"

class HotwireLifecycleTest < ApplicationSystemTestCase
  test "Turbo Drive reconnects interactive components without duplicate roots" do
    visit gallery_component_path("tabs")

    assert_stimulus_controller("#gallery-tabs-settings", "nk--tabs")
    click_tabs_general

    within("[data-gallery='sidebar']") { click_link("Dialog") }

    assert_current_path gallery_component_path("dialog")
    assert_selector "#gallery-dialog-remove-member:not([data-controller])"
    find("#gallery-dialog-remove-member [data-slot='dialog-trigger']").click
    assert_selector "#gallery-dialog-remove-member [data-slot='dialog-panel'][open]"
    find("body").send_keys(:escape)
    assert_no_selector "#gallery-dialog-remove-member [data-slot='dialog-panel'][open]"

    within("[data-gallery='sidebar']") { click_link("Tabs") }

    assert_current_path gallery_component_path("tabs")
    assert_selector "#gallery-tabs-settings", count: 1
    assert_stimulus_controller("#gallery-tabs-settings", "nk--tabs")
    click_tabs_general
    assert_no_severe_console_errors
  end

  test "Turbo Frame handles validation and success stream replacements" do
    visit new_registration_path
    execute_script("document.querySelector('#details_registration').noValidate = true")

    within("turbo-frame#form_registration") do
      fill_in "Email", with: "valid@example.test"
      click_button "Register"
    end

    assert_current_path new_registration_path
    assert_selector "turbo-frame#form_registration #registration_email[value='valid@example.test']"
    assert_selector "turbo-frame#form_registration #registration_role[aria-invalid='true']"
    assert_selector "turbo-frame#form_registration #registration_terms[aria-invalid='true']", visible: :all
    assert_selector "turbo-frame#form_registration [data-slot='field-error']", minimum: 2
    assert_expected_validation_console_entries

    within("turbo-frame#form_registration") do
      fill_in "Email", with: "dev@example.test"
      select "Developer", from: "Role"
      check "I accept the terms", allow_label_click: true
      click_button "Register"
    end

    assert_current_path new_registration_path
    assert_selector "turbo-frame#form_registration h1", text: "Registration received"
    assert_selector "turbo-frame#form_registration a", text: "Create another"
    assert_no_severe_console_errors
  end

  test "Turbo refresh morph reconnects tabs and toast behavior once" do
    visit gallery_component_path("tabs")
    install_morph_counter
    refresh_with_turbo_stream

    wait_until { evaluate_script("window.__nitroMorphCount") == 1 }
    assert_selector "#gallery-tabs-settings", count: 1
    assert_stimulus_controller("#gallery-tabs-settings", "nk--tabs")
    click_tabs_general

    visit gallery_component_path("toast")
    install_morph_counter
    refresh_with_turbo_stream

    wait_until { evaluate_script("window.__nitroMorphCount") == 1 }
    assert_selector "#gallery-toast-permanent", count: 1
    assert_stimulus_controller("#gallery-toast-permanent", "nk--toast")
    assert_selector "#gallery-toast-variants [data-nk='toast-item']", count: 5
    first("#gallery-toast-variants [data-slot='toast-item-dismiss']").click
    assert_selector "#gallery-toast-variants [data-nk='toast-item']", count: 4
    assert_no_severe_console_errors
  end

  private

  def assert_stimulus_controller(selector, identifier)
    assert_selector selector, count: 1
    connected = evaluate_script(<<~JAVASCRIPT, selector, identifier)
      window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector(arguments[0]),
        arguments[1]
      ) !== null
    JAVASCRIPT
    assert connected, "Expected #{identifier} to be connected at #{selector}"
  end

  def click_tabs_general
    find("#gallery-tabs-settings-general-tab").click
    assert_selector "#gallery-tabs-settings-general-tab[aria-selected='true'][data-state='active']"
    assert_selector "#gallery-tabs-settings-general-panel:not([hidden])[data-state='active']"
    assert_selector "#gallery-tabs-settings [data-slot='tabs-tab'][aria-selected='true']", count: 1
  end

  def install_morph_counter
    execute_script <<~JAVASCRIPT
      window.__nitroMorphCount = 0;
      document.addEventListener("turbo:morph", () => window.__nitroMorphCount += 1, { once: true });
    JAVASCRIPT
  end

  def refresh_with_turbo_stream
    execute_script <<~JAVASCRIPT
      Turbo.renderStreamMessage('<turbo-stream action="refresh"></turbo-stream>');
    JAVASCRIPT
  end

  def assert_expected_validation_console_entries
    unexpected = browser_console_entries.select do |entry|
      entry.level == "SEVERE" && !entry.message.include?("422")
    end

    assert_empty unexpected, "Unexpected console errors during the intentional 422 validation response"
  end
end
