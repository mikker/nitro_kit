require "application_system_test_case"

# Data-entry controls read --nk-text-base below the md breakpoint, where a
# focused control under 16px would zoom the viewport, and --nk-text-sm from
# md up. Buttons read --nk-text-sm at every width.
class ControlTextTest < ApplicationSystemTestCase
  test "control text keys to the width axis" do
    visit gallery_component_path("input")
    original = current_window.size

    sizes = evaluate_script(measure_script)
    assert_equal "14/14/14/14", sizes, "wide viewports read at --nk-text-sm"

    current_window.resize_to(600, 900)
    sizes = evaluate_script(measure_script)
    assert_equal "16/16/16/14", sizes,
      "narrow viewports read data-entry controls at --nk-text-base"
  ensure
    current_window.resize_to(*original) if original
  end

  test "buttons keep their size and grow only their touch target on coarse pointers" do
    visit gallery_component_path("input")

    heights = evaluate_script(height_script)
    assert_equal "36/36/36", heights, "fine pointers render the 36px default"

    browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 5)
    heights = evaluate_script(height_script)
    assert_equal "36/36/36", heights, "coarse pointers keep the rendered size"

    hit = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const probe = document.createElement("div");
        probe.style.cssText = "position: fixed; inset-block-start: 100px; inset-inline-start: 100px; padding: 40px;";
        probe.innerHTML = '<button data-nk="button" data-size="md">Save</button>';
        document.body.appendChild(probe);
        const button = probe.querySelector("button");
        const rect = button.getBoundingClientRect();
        const below = document.elementFromPoint(
          rect.left + rect.width / 2,
          rect.bottom + 3
        );
        probe.remove();
        return below === button ? "extended" : "not-extended";
      })()
    JAVASCRIPT
    assert_equal "extended", hit,
      "a tap just outside the rendered button still lands on it"
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
