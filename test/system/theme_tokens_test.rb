require "application_system_test_case"

# Theming is scoped `--nk-*` overrides on an application-owned wrapper, inherited
# by every Nitro descendant. This is the behavior the retired customization
# studio actually proved about theming, kept without the studio UI.
class ThemeTokensTest < ApplicationSystemTestCase
  test "scoped --nk-* overrides on a wrapper reach Nitro components through inheritance" do
    visit gallery_component_path("button")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const button = document.querySelector('[data-nk="button"][data-variant="primary"]');
        const before = getComputedStyle(button);
        const baseline = {
          background: before.backgroundColor,
          radius: before.borderTopLeftRadius
        };

        const wrapper = document.createElement("div");
        wrapper.style.setProperty("--nk-color-primary", "rgb(0, 128, 0)");
        wrapper.style.setProperty("--nk-radius-lg", "13px");
        button.parentNode.insertBefore(wrapper, button);
        wrapper.appendChild(button);

        const after = getComputedStyle(button);
        return {
          baseline,
          scoped: { background: after.backgroundColor, radius: after.borderTopLeftRadius }
        };
      })()
    JAVASCRIPT

    scoped = computed.fetch("scoped")

    refute_equal computed.fetch("baseline"), scoped
    assert_equal "rgb(0, 128, 0)", scoped.fetch("background")
    assert_equal "13px", scoped.fetch("radius")
    assert_no_severe_console_errors
  end
end
