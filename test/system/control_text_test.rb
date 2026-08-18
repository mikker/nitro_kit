require "application_system_test_case"

# Data-entry controls and the default Button read at the same size on either
# pointer: --nk-text-sm on fine pointers, --nk-text-base on coarse ones, where
# iOS Safari would zoom a focused control below 16px. Chromium emulates the
# media feature; real-device iOS behavior is covered by the manual release
# check in docs/browser_support.md.
class ControlTextTest < ApplicationSystemTestCase
  test "controls and buttons read at one size per pointer" do
    visit gallery_component_path("input")

    sizes = evaluate_script(measure_script)
    assert_equal "14/14/14/14", sizes, "fine pointers read at --nk-text-sm"

    browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 5)
    sizes = evaluate_script(measure_script)
    assert_equal "16/16/16/16", sizes, "coarse pointers read at --nk-text-base"
  ensure
    browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: false)
  end

  test "default controls meet the 44px touch target on coarse pointers" do
    visit gallery_component_path("input")

    heights = evaluate_script(height_script)
    assert_equal "40/40/40", heights, "fine pointers keep the 40px default"

    browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 5)
    heights = evaluate_script(height_script)
    assert_equal "44/44/44", heights, "coarse pointers adopt the large step"
  ensure
    browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: false)
  end

  private

  def height_script
    <<~JAVASCRIPT
      (() => {
        const probe = document.createElement("div");
        probe.innerHTML = [
          '<input data-nk="input" type="text">',
          '<div data-nk="select"><select data-slot="select-control"></select></div>',
          '<button data-nk="button" data-size="md">Save</button>'
        ].join("");
        document.body.appendChild(probe);
        const height = (selector) =>
          Math.round(probe.querySelector(selector).getBoundingClientRect().height);
        const result = [
          height('[data-nk="input"]'),
          height('[data-slot="select-control"]'),
          height('[data-nk="button"]')
        ].join("/");
        probe.remove();
        return result;
      })()
    JAVASCRIPT
  end

  def measure_script
    <<~JAVASCRIPT
      (() => {
        const probe = document.createElement("div");
        probe.innerHTML = [
          '<input data-nk="input" type="text">',
          '<div data-nk="select"><select data-slot="select-control"></select></div>',
          '<textarea data-nk="textarea"></textarea>',
          '<button data-nk="button" data-size="md">Save</button>'
        ].join("");
        document.body.appendChild(probe);
        const size = (selector) =>
          Math.round(parseFloat(getComputedStyle(probe.querySelector(selector)).fontSize));
        const result = [
          size('[data-nk="input"]'),
          size('[data-slot="select-control"]'),
          size('[data-nk="textarea"]'),
          size('[data-nk="button"]')
        ].join("/");
        probe.remove();
        return result;
      })()
    JAVASCRIPT
  end
end
