require "application_system_test_case"

class GalleryShellTest < ApplicationSystemTestCase
  test "gallery command palette narrows destinations and visits the selected result" do
    visit gallery_root_path

    trigger = "#gallery-filter [data-slot='command-palette-trigger']"
    panel = "#gallery-filter [data-slot='command-palette-panel']"
    input = "#gallery-filter [data-slot='command-palette-input']"
    destination = "#gallery-filter [data-slot='command-palette-destination']"

    find(trigger).click
    assert_selector "#{panel}[open]"
    assert_focused input
    find(input).send_keys("Button to")

    assert_equal [ "Button to" ], evaluate_script(<<~JAVASCRIPT)
      Array.from(document.querySelectorAll("#{destination}"))
        .filter((link) => !link.hidden)
        .map((link) => link.querySelector("[data-slot='command-palette-destination-label']").textContent.trim());
    JAVASCRIPT
    assert_selector "#gallery-filter [data-slot='command-palette-status']",
      text: "1 destination available.", visible: :all

    assert_current_path gallery_root_path
    find(input).send_keys(:enter)

    assert_current_path gallery_component_path("button-to")
    assert_selector "#{panel}:not([open])", visible: :all
    assert_equal "", find(input, visible: :all).value
    assert_selector "#gallery-navigation a[href='/gallery/components/button-to']" \
      "[aria-current='page'][data-state='current']"

    find(trigger).click
    assert_selector destination, count: 3 + Gallery::Catalog.collections.sum { _1.entries.size }
    assert_no_selector "#{destination}[hidden]", visible: :all
    find("#{destination}[href='#{gallery_guide_path}']").click

    assert_current_path gallery_guide_path
    assert_no_severe_console_errors
  end

  test "command-k opens and closes the gallery command palette" do
    visit gallery_root_path

    panel = "#gallery-filter [data-slot='command-palette-panel']"
    input = "#gallery-filter [data-slot='command-palette-input']"
    trigger = "#gallery-filter [data-slot='command-palette-trigger']"
    execute_script("arguments[0].focus()", find(trigger))
    execute_script(<<~JAVASCRIPT)
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "k", metaKey: true, bubbles: true }));
    JAVASCRIPT

    assert_selector "#{panel}[open]"
    assert_focused input

    execute_script(<<~JAVASCRIPT)
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "k", metaKey: true, bubbles: true }));
    JAVASCRIPT

    assert_selector "#{panel}:not([open])", visible: :all
    assert_focused trigger
    assert_no_severe_console_errors
  end

  test "permanent navigation keeps its scroll while current state follows Turbo visits" do
    visit gallery_root_path

    body = "#gallery-navigation > [data-slot='app-navigation-body']"
    execute_script(<<~JAVASCRIPT)
      window.__galleryNavigation = document.querySelector("#gallery-navigation");
      document.querySelector("#{body}").scrollTop = 400;
      document.querySelector("#gallery-navigation a[href='/gallery/agent-guide']").click();
    JAVASCRIPT

    assert_current_path gallery_agent_guide_path
    assert_equal true, evaluate_script(
      "window.__galleryNavigation === document.querySelector('#gallery-navigation')"
    )
    wait_until(message: "Expected permanent gallery navigation to retain its scroll position") do
      evaluate_script("document.querySelector(arguments[0]).scrollTop", body) == 400
    end
    assert_selector "#gallery-navigation a[href='/gallery/agent-guide'][aria-current='page'][data-state='current']"
    assert_selector "#gallery-navigation a[href='/gallery']:not([aria-current])[data-state='default']"
    assert_no_severe_console_errors
  end

  test "gallery dogfoods the responsive application shell and navigation" do
    visit gallery_root_path

    assert_selector "#gallery-shell[data-nk='app-shell'][data-layout='sidebar'][data-enhanced]"
    assert_selector "#gallery-navigation[data-nk='app-navigation']", count: 1
    assert_selector "#gallery-navigation a[href='/gallery'][aria-current='page']", text: "Introduction"
    widths = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const body = document.querySelector(
          "#gallery-navigation > [data-slot='app-navigation-body']"
        );
        return {
          filter: document.querySelector("#gallery-filter").getBoundingClientRect().width,
          item: document.querySelector(
            "#gallery-navigation [data-slot='app-navigation-item-link']"
          ).getBoundingClientRect().width,
          scrollbar: body.offsetWidth - body.clientWidth
        };
      })()
    JAVASCRIPT
    assert_equal widths.fetch("item") + widths.fetch("scrollbar"), widths.fetch("filter")

    resize_viewport(width: 390, height: 844)
    trigger = "#gallery-shell [data-slot='app-shell-mobile-trigger']"
    dialog = "#gallery-shell > [data-slot='app-shell-dialog']"

    find(trigger).click

    assert_selector "#gallery-shell[data-state='open']"
    assert_selector "#{dialog}[open] #gallery-navigation", count: 1
    assert_equal true, evaluate_script("document.querySelector(arguments[0]).matches(':modal')", dialog)

    find("#gallery-filter [data-slot='command-palette-trigger']").click
    command_panel = "#gallery-filter [data-slot='command-palette-panel']"
    assert_selector "#{command_panel}[open]"
    find("#gallery-filter [data-slot='command-palette-close']").click
    assert_selector "#{command_panel}:not([open])", visible: :all

    within("#gallery-navigation") { click_link("Button", exact: true) }

    assert_current_path gallery_component_path("button")
    assert_selector "#gallery-shell[data-state='closed'][data-enhanced]"
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#gallery-navigation a[href='/gallery/components/button'][aria-current='page']",
      text: "Button", visible: :all
    assert_equal false, evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
    assert_no_severe_console_errors
  end
end
