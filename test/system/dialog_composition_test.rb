require "application_system_test_case"

class DialogCompositionTest < ApplicationSystemTestCase
  test "dialog isolates alignment and keeps its header and actions clear at every width" do
    [ 1440, 390 ].each do |width|
      resize_viewport(width:, height: 1000)
      browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1000, deviceScaleFactor: 1, mobile: false)
      visit gallery_component_path("dialog")
      assert_equal width, evaluate_script("innerWidth")
      execute_script("document.documentElement.dataset.theme = 'dark'")
      root = "#gallery-dialog-remove-member"
      execute_script("document.querySelector(arguments[0]).parentElement.style.textAlign = 'right'", root)
      find("#{root} [data-slot='dialog-trigger']").click
      panel = find("#{root} [data-slot='dialog-panel'][open]")
      wait_until { evaluate_script("getComputedStyle(arguments[0]).opacity", panel) == "1" }
      assert_equal "start", evaluate_script("getComputedStyle(arguments[0]).textAlign", panel)
      geometry = evaluate_script(<<~JS, panel)
        (() => {
        const panel = arguments[0];
        const rect = slot => panel.querySelector(`[data-slot="dialog-${slot}"]`).getBoundingClientRect();
        const header = rect("header"), close = rect("close"), body = rect("body");
        return { headerRight: header.right, closeLeft: close.left, bodyTop: body.top,
          headerBottom: header.bottom, closeBottom: close.bottom,
          overflow: panel.scrollWidth - panel.clientWidth };
        })()
      JS
      assert_operator geometry["headerRight"], :<=, geometry["closeLeft"]
      assert_operator geometry["bodyTop"], :>=, geometry["headerBottom"]
      assert_operator geometry["bodyTop"], :>=, geometry["closeBottom"]
      assert_operator geometry["overflow"], :<=, 1
      page.save_screenshot(Rails.root.join("tmp/dialog-composition-#{width}.png")) if ENV["COMPOSITION_SCREENSHOTS"]
      within(panel) do
        cancel = find_button("Cancel")
        remove = find_button("Remove team member")
        if width == 1440
          assert_in_delta cancel.native.rect.y, remove.native.rect.y, 1
        end
        click_button "Cancel"
      end
      assert_no_selector "#{root} [data-slot='dialog-panel'][open]"
      assert_equal true, evaluate_script("document.activeElement === arguments[0]", find("#{root} [data-slot='dialog-trigger']"))
    end
  end
end
