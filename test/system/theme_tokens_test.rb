require "application_system_test_case"

# Theming is scoped `--nk-*` overrides on an application-owned wrapper, inherited
# by every Nitro descendant. This is the behavior the retired customization
# studio actually proved about theming, kept without the studio UI.
class ThemeTokensTest < ApplicationSystemTestCase
  test "a button radius override does not change input shape" do
    visit gallery_component_path("button")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const wrapper = document.createElement("div");
        wrapper.style.setProperty("--nk-button-radius", "9999px");

        const button = document.querySelector('[data-nk="button"][data-variant="primary"]');
        const input = document.createElement("input");
        input.dataset.nk = "input";
        wrapper.appendChild(button);
        wrapper.appendChild(input);
        document.body.appendChild(wrapper);

        return {
          button: getComputedStyle(button).borderTopLeftRadius,
          input: getComputedStyle(input).borderTopLeftRadius
        };
      })()
    JAVASCRIPT

    assert_equal "9999px", computed.fetch("button")
    refute_equal "9999px", computed.fetch("input")
    assert_no_severe_console_errors
  end

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

  test "data-nk-scheme selects the palette for named host themes" do
    visit gallery_component_path("button")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        // A light ancestor makes the unhinted named theme's inheritance explicit.
        const host = document.createElement("div");
        host.dataset.theme = "light";
        document.body.appendChild(host);

        const probe = (attributes) => {
          const element = document.createElement("div");
          Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value));
          host.appendChild(element);
          const style = getComputedStyle(element);
          const result = {
            scheme: style.colorScheme,
            success: style.getPropertyValue("--nk-color-success-content").trim()
          };
          element.remove();
          return result;
        };

        const results = {
          light: probe({ "data-theme": "light" }),
          dark: probe({ "data-theme": "dark" }),
          night: probe({ "data-theme": "night" }),
          nightDark: probe({ "data-theme": "night", "data-nk-scheme": "dark" }),
          forcedLight: probe({ "data-theme": "dark", "data-nk-scheme": "light" })
        };
        host.remove();
        return results;
      })()
    JAVASCRIPT

    assert_equal "dark", computed.dig("dark", "scheme")
    assert_equal computed.fetch("dark"), computed.fetch("nightDark")
    assert_equal computed.fetch("light"), computed.fetch("forcedLight")
    assert_equal computed.fetch("light"), computed.fetch("night")
    refute_equal computed.dig("dark", "success"), computed.dig("night", "success")
    assert_no_severe_console_errors
  end

  test "revert-layer inside nitro-kit.aliases drops one alias so a host bridge does not cycle" do
    visit gallery_component_path("button")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const style = document.createElement("style");
        style.textContent = `
          @layer base { [data-theme="night"] { --color-primary: rgb(1, 2, 3); } }
          @layer nitro-kit.aliases { [data-theme="night"] { --color-primary: revert-layer; } }
          [data-theme="night"] { --nk-color-primary: var(--color-primary); }
        `;
        document.head.appendChild(style);

        const scope = document.createElement("div");
        scope.dataset.theme = "night";
        scope.dataset.nkScheme = "dark";
        const button = document.querySelector('[data-nk="button"][data-variant="primary"]');
        scope.appendChild(button);
        document.body.appendChild(scope);

        return {
          background: getComputedStyle(button).backgroundColor,
          border: getComputedStyle(scope).getPropertyValue("--color-border").trim()
        };
      })()
    JAVASCRIPT

    assert_equal "rgb(1, 2, 3)", computed.fetch("background")
    refute_empty computed.fetch("border"), "other aliases keep resolving"
    assert_no_severe_console_errors
  end
end
