require "application_system_test_case"

class CommandPaletteSystemTest < ApplicationSystemTestCase
  test "filters destinations and keeps native dialog and link behavior" do
    visit gallery_component_path("command-palette")

    root = "#gallery-command-palette-workspace"
    trigger = "#{root} [data-slot='command-palette-trigger']"
    panel = "#{root} [data-slot='command-palette-panel']"
    input = "#{root} [data-slot='command-palette-input']"
    destination = "#{root} [data-slot='command-palette-destination']"

    assert_selector "#{root}[data-enhanced]"
    assert_no_selector "#{trigger}[command]"
    assert_no_selector "#{trigger}[commandfor]"
    find(trigger).click

    assert_selector "#{panel}[open]"
    assert_focused input
    wait_until(message: "command palette animation did not settle") do
      find(panel).evaluate_script(
        "this.getAnimations().every((animation) => animation.playState === 'finished')"
      )
    end
    panel_top = find(panel).evaluate_script("this.getBoundingClientRect().top")

    find(input).send_keys("billing")

    assert_selector "#{destination}:not([hidden])", count: 1, text: "Billing"
    assert_in_delta panel_top, find(panel).evaluate_script("this.getBoundingClientRect().top"), 0.5
    assert_selector "#{root} [data-slot='command-palette-status']",
      text: "1 destination available.", visible: :all

    find(input).send_keys(:arrow_down)
    assert_focused "#{destination}[href='#billing']"
    active_element.send_keys(:escape)

    assert_selector "#{panel}:not([open])", visible: :all
    assert_focused trigger

    find(trigger).click
    find(input).send_keys("missing")

    assert_selector "#{root} [data-slot='command-palette-empty']", text: "No destinations found."
    assert_selector "#{root} [data-slot='command-palette-status']",
      text: "No destinations found.", visible: :all
    assert_no_selector "#{destination}:not([hidden])"

    find("#{root} [data-slot='command-palette-close']").click
    execute_script("document.querySelector(arguments[0]).removeAttribute('data-controller')", root)

    assert_selector "#{root}:not([data-enhanced])"
    assert_selector "#{root} [data-slot='command-palette-search'][hidden]", visible: :all
    assert_no_selector "#{destination}[hidden]", visible: :all
    assert_selector "#{trigger}[command='show-modal']"

    find(trigger).click

    assert_selector "#{panel}[open]"
    assert_selector destination, count: 5
    find("#{root} [data-slot='command-palette-close']").click
    assert_selector "#{panel}:not([open])", visible: :all
    assert_no_severe_console_errors
  end

  test "replaces remote results through the owned Turbo Frame" do
    visit gallery_component_path("command-palette")

    root = "#gallery-command-palette-async"
    input = "#{root} [data-slot='command-palette-input']"
    destination = "#{root} [data-slot='command-palette-destination']"
    frame = "#{root} turbo-frame#gallery-command-palette-async-results-frame"

    find("#{root} [data-slot='command-palette-trigger']").click
    assert_selector destination, count: 5

    find(input).send_keys("billing")
    assert_selector "#{destination}:not([hidden])", count: 1, text: "Billing"
    assert_selector "#{root} [data-slot='command-palette-status']",
      text: "1 destination available.", visible: :all
    assert_no_selector "#{frame}[aria-busy='true']"

    find(input).set("missing")
    assert_selector "#{root} [data-slot='command-palette-empty']", text: "No destinations found."
    assert_no_selector destination

    find(input).set("buttons")
    assert_selector "#{destination}:not([hidden])", count: 1, text: "Buttons"
    find(input).send_keys(:enter)

    assert_current_path gallery_component_path("button")
    assert_no_severe_console_errors
  end

  test "opens and closes through the shared fallback when commands are stripped" do
    visit gallery_component_path("command-palette")

    root = "#gallery-command-palette-workspace"
    trigger = "#{root} [data-slot='command-palette-trigger']"
    panel = "#{root} [data-slot='command-palette-panel']"
    close = "#{root} [data-slot='command-palette-close']"
    execute_script(<<~JAVASCRIPT, trigger, close)
      for (const selector of [arguments[0], arguments[1]]) {
        const control = document.querySelector(selector);
        control.removeAttribute("command");
        control.removeAttribute("commandfor");
      }
    JAVASCRIPT

    find(trigger).click
    assert_selector "#{panel}[open]"
    assert_focused "#{root} [data-slot='command-palette-input']"
    find(close).click
    assert_selector "#{panel}:not([open])", visible: :all
    assert_focused trigger
    assert_no_severe_console_errors
  end

  test "does not open from its trigger while another modal is active" do
    visit gallery_component_path("command-palette")

    root = "#gallery-command-palette-workspace"
    trigger = "#{root} [data-slot='command-palette-trigger']"
    panel = "#{root} [data-slot='command-palette-panel']"

    execute_script(<<~JAVASCRIPT)
      const activeModal = document.createElement("dialog");
      activeModal.id = "active-modal";
      document.body.append(activeModal);
      activeModal.showModal();
    JAVASCRIPT

    assert_selector "dialog#active-modal[open]", visible: :all
    wait_until(message: "active modal did not enter the top layer") do
      evaluate_script("document.querySelector('#active-modal').matches(':modal')")
    end
    execute_script("document.querySelector(arguments[0]).click()", trigger)
    assert_selector "#{panel}:not([open])", visible: :all
    assert_no_severe_console_errors
  ensure
    execute_script("document.querySelector('#active-modal')?.remove()")
  end
end
