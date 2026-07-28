require "application_system_test_case"

class GalleryShellTest < ApplicationSystemTestCase
  test "gallery filter narrows destinations and visits the selected result" do
    visit gallery_root_path

    input = "#gallery-filter-input"
    find(input).click
    find(input).send_keys("Button group")

    assert_selector "#gallery-filter[data-state='open']"
    listbox = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const listbox = document.querySelector("#gallery-filter-listbox");
        return {
          hidden: listbox.hidden,
          state: listbox.dataset.state,
          rootState: document.querySelector("#gallery-filter").dataset.state,
          input: document.querySelector("#{input}").value
        };
      })()
    JAVASCRIPT
    assert_equal false, listbox.fetch("hidden"), listbox.inspect
    assert_equal [ "Radio button group", "Button group" ], evaluate_script(<<~JAVASCRIPT)
      Array.from(document.querySelectorAll("#gallery-filter [data-slot='combobox-option']"))
        .filter((option) => !option.hidden)
        .map((option) => option.querySelector("[data-slot='combobox-option-label']").textContent.trim());
    JAVASCRIPT
    assert_selector "#gallery-filter [data-slot='combobox-status']",
      text: "2 options available.", visible: :all

    assert_current_path gallery_root_path
    find(input).send_keys(:enter)

    assert_current_path gallery_component_path("button-group")
    assert_equal "", find(input).value
    assert_selector "#gallery-navigation a[href='/gallery/components/button-group']" \
      "[aria-current='page'][data-state='current']"

    find(input).click
    option = "#gallery-filter [data-slot='combobox-option']"
    assert_selector option, count: 3 + Gallery::Catalog.collections.sum { _1.entries.size }
    assert_no_selector "#{option}[hidden]", visible: :all
    find("#{option}[data-value='#{gallery_guide_path}']").click

    assert_current_path gallery_guide_path
    assert_equal "", find(input).value
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
      (() => ({
        filter: document.querySelector("#gallery-filter").getBoundingClientRect().width,
        item: document.querySelector(
          "#gallery-navigation [data-slot='app-navigation-item-link']"
        ).getBoundingClientRect().width
      }))()
    JAVASCRIPT
    assert_equal widths.fetch("item"), widths.fetch("filter")

    resize_viewport(width: 390, height: 844)
    trigger = "#gallery-shell [data-slot='app-shell-mobile-trigger']"
    dialog = "#gallery-shell > [data-slot='app-shell-dialog']"

    find(trigger).click

    assert_selector "#gallery-shell[data-state='open']"
    assert_selector "#{dialog}[open] #gallery-navigation", count: 1
    assert_equal true, evaluate_script("document.querySelector(arguments[0]).matches(':modal')", dialog)

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
