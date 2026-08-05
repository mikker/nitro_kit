require "application_system_test_case"

class HotwireLifecycleTest < ApplicationSystemTestCase
  test "command palette resets filtering across Turbo removal and reconnection" do
    visit gallery_component_path("command-palette")

    root = "#gallery-command-palette-workspace"
    input = "#{root} [data-slot='command-palette-input']"
    destination = "#{root} [data-slot='command-palette-destination']"
    assert_stimulus_controller(root, "nk--command-palette")

    find("#{root} [data-slot='command-palette-trigger']").click
    find(input).send_keys("buttons")
    assert_selector "#{destination}:not([hidden])", count: 1
    find(input).send_keys(:enter)

    assert_current_path gallery_component_path("button")
    click_gallery_navigation_link("Command palette")

    assert_current_path gallery_component_path("command-palette")
    assert_stimulus_controller(root, "nk--command-palette")
    assert_equal "", find(input, visible: :all).value
    assert_no_selector "#{destination}[hidden]", visible: :all
    assert_no_severe_console_errors
  end

  test "Turbo Drive reconnects interactive components without duplicate roots" do
    visit gallery_component_path("tabs")

    assert_stimulus_controller("#gallery-tabs-settings", "nk--tabs")
    click_tabs_general

    click_gallery_navigation_link("Dialog")

    assert_current_path gallery_component_path("dialog")
    assert_stimulus_controller("#gallery-dialog-remove-member", "nk--dialog")
    find("#gallery-dialog-remove-member [data-slot='dialog-trigger']").click
    assert_selector "#gallery-dialog-remove-member [data-slot='dialog-panel'][open]"
    find("body").send_keys(:escape)
    assert_no_selector "#gallery-dialog-remove-member [data-slot='dialog-panel'][open]"

    click_gallery_navigation_link("Tabs")

    assert_current_path gallery_component_path("tabs")
    assert_selector "#gallery-tabs-settings", count: 1
    assert_stimulus_controller("#gallery-tabs-settings", "nk--tabs")
    click_tabs_general
    assert_no_severe_console_errors
  end

  test "Turbo cache closes dialogs and reconnect preserves the fallback" do
    visit gallery_component_path("dialog")

    root = "#gallery-dialog-remove-member"
    trigger = "#{root} [data-slot='dialog-trigger']"
    panel = "#{root} [data-slot='dialog-panel']"
    find(trigger).click
    assert_selector "#{panel}[open]"

    execute_script("document.dispatchEvent(new Event('turbo:before-cache'))")
    assert_selector "#{panel}:not([open])", visible: :all

    click_gallery_navigation_link("Tabs")
    click_gallery_navigation_link("Dialog")
    assert_stimulus_controller(root, "nk--dialog")
    execute_script(<<~JAVASCRIPT, trigger)
      const control = document.querySelector(arguments[0]);
      control.removeAttribute("command");
      control.removeAttribute("commandfor");
    JAVASCRIPT
    find(trigger).click
    assert_selector "#{panel}[open]"
    assert_no_severe_console_errors
  end

  test "Turbo Frame handles validation and success stream replacements" do
    visit new_registration_path
    execute_script("document.querySelector('#details_registration').noValidate = true")

    within("turbo-frame#form_registration") do
      fill_in "Email", with: "valid@example.test"
      fill_in "Note", with: "Preserve this note through both mutations"
      click_button "Register"
    end

    assert_current_path new_registration_path
    assert_selector "turbo-frame#form_registration #registration_email[value='valid@example.test']"
    assert_field "Note", with: "Preserve this note through both mutations"
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
    within("turbo-frame#form_registration") do
      assert_selector "h1", text: "Registration received"
      assert_selector "[data-application-component='status-pill']", text: "Received"
      assert_text "dev@example.test"
      assert_text "Preserve this note through both mutations"
      assert_link "Create another"
    end
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
