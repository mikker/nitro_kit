require "application_system_test_case"

# Alert and Toast::Item share one variant vocabulary. Before the semantic palette
# they resolved it from two different sources — Alert from a private hardcoded
# hue, Toast from `--nk-color-*` — so the same variant rendered as two different
# colors and rethemeing a semantic token moved only one of them.
class SemanticPaletteTest < ApplicationSystemTestCase
  test "an alert and a toast of the same variant resolve to the same colors" do
    visit gallery_component_path("alert")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const read = (nk, variant) => {
          const node = document.createElement("div");
          node.dataset.nk = nk;
          node.dataset.variant = variant;
          document.body.appendChild(node);
          const style = getComputedStyle(node);
          const value = [
            style.backgroundColor,
            style.borderTopColor,
            style.color
          ].join(" / ");
          node.remove();
          return value;
        };

        return ["default", "info", "success", "warning", "error"].map(
          (variant) => [
            variant,
            read("alert", variant),
            read("toast-item", variant)
          ].join(" | ")
        );
      })()
    JAVASCRIPT

    computed.each do |row|
      variant, alert_colors, toast_colors = row.split(" | ")

      assert_equal alert_colors, toast_colors,
        "Alert and Toast disagree about #{variant}"
    end

    assert_no_severe_console_errors
  end

  # Replaces a narrower test that pinned one literal oklch value to keep warning
  # badges legible. Asserting the contrast requirement itself covers every
  # semantic family in both appearances, and survives a change of palette.
  test "every semantic family clears WCAG AA against its own tint" do
    visit gallery_component_path("badge")

    measurements = evaluate_script(<<~JAVASCRIPT)
      (() => {
        // Computed colors come back as oklab(), so resolve through a canvas to
        // get real sRGB bytes.
        const ctx = document
          .createElement("canvas")
          .getContext("2d", { willReadFrequently: true });
        const toRgba = (color) => {
          ctx.clearRect(0, 0, 1, 1);
          ctx.fillStyle = color;
          ctx.fillRect(0, 0, 1, 1);
          const d = ctx.getImageData(0, 0, 1, 1).data;
          return [d[0], d[1], d[2], d[3] / 255];
        };
        const over = (fg, bg) =>
          fg.slice(0, 3).map((c, i) => c * fg[3] + bg[i] * (1 - fg[3]));
        const luminance = (rgb) => {
          const channel = (c) => {
            c = c / 255;
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
          };
          return (
            0.2126 * channel(rgb[0]) +
            0.7152 * channel(rgb[1]) +
            0.0722 * channel(rgb[2])
          );
        };
        const ratio = (a, b) => {
          const [high, low] = [luminance(a), luminance(b)].sort((m, n) => n - m);
          return (high + 0.05) / (low + 0.05);
        };

        const original = document.documentElement.dataset.theme;
        const out = [];

        for (const theme of ["light", "dark"]) {
          document.documentElement.dataset.theme = theme;
          const page = toRgba(getComputedStyle(document.body).backgroundColor);

          const measure = (nk, attribute, value) => {
            const node = document.createElement("div");
            node.dataset.nk = nk;
            node.dataset[attribute] = value;
            document.body.appendChild(node);
            const style = getComputedStyle(node);
            const background = over(toRgba(style.backgroundColor), page);
            const foreground = over(toRgba(style.color), background);
            out.push(
              [theme, nk, value, ratio(foreground, background).toFixed(2)].join(" ")
            );
            node.remove();
          };

          for (const variant of ["default", "info", "success", "warning", "error"]) {
            measure("alert", "variant", variant);
            measure("toast-item", "variant", variant);
          }
          for (const color of #{NitroKit::Badge::COLORS.map(&:to_s).inspect}) {
            measure("badge", "color", color);
          }
        }

        if (original === undefined) {
          delete document.documentElement.dataset.theme;
        } else {
          document.documentElement.dataset.theme = original;
        }
        return out;
      })()
    JAVASCRIPT

    assert_predicate measurements, :any?

    failures = measurements.filter_map do |row|
      theme, component, value, contrast = row.split
      "#{component} #{value} (#{theme}) #{contrast}:1" if contrast.to_f < 4.5
    end

    assert_empty failures, "below WCAG AA: #{failures.join(", ")}"

    assert_no_severe_console_errors
  end

  # Each semantic family defaults to the exact steps of its hue family, so the
  # two vocabularies agree out of the box: `info` is `blue`, `danger` is `red`,
  # and rethemeing one does not disturb the other.
  test "each semantic badge renders identically to its hue family" do
    visit gallery_component_path("badge")

    pairs = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const read = (color) => {
          const node = document.createElement("span");
          node.dataset.nk = "badge";
          node.dataset.color = color;
          document.body.appendChild(node);
          const style = getComputedStyle(node);
          const value = [style.backgroundColor, style.color].join(" / ");
          node.remove();
          return value;
        };

        return Object.entries({
          neutral: "zinc", info: "blue", success: "green",
          warning: "amber", danger: "red"
        }).map(([semantic, hue]) =>
          [semantic, hue, read(semantic), read(hue)].join(" | ")
        );
      })()
    JAVASCRIPT

    pairs.each do |row|
      semantic, hue, semantic_colors, hue_colors = row.split(" | ")

      assert_equal hue_colors, semantic_colors,
        "a #{semantic} badge should render exactly like a #{hue} badge"
    end

    assert_no_severe_console_errors
  end

  test "rethemeing one tint role moves badge, alert, and toast together" do
    visit gallery_component_path("badge")

    computed = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const wrapper = document.createElement("div");
        document.body.append(wrapper);

        const build = (nk, attribute, value) => {
          const node = document.createElement("span");
          node.dataset.nk = nk;
          node.dataset[attribute] = value;
          wrapper.append(node);
          return node;
        };

        const badge = build("badge", "color", "success");
        const alert = build("alert", "variant", "success");
        const toast = build("toast-item", "variant", "success");
        const untouched = build("badge", "color", "green");
        const read = () => [badge, alert, toast].map(
          (node) => getComputedStyle(node).backgroundColor
        );

        const before = read();
        const greenBefore = getComputedStyle(untouched).backgroundColor;
        wrapper.style.setProperty("--nk-palette-success", "rgb(0, 128, 0)");
        const after = read();
        const greenAfter = getComputedStyle(untouched).backgroundColor;

        return { before, after, green: [greenBefore, greenAfter] };
      })()
    JAVASCRIPT

    green_before, green_after = computed.fetch("green")

    assert_equal green_before, green_after,
      "rethemeing the semantic tint must not move the raw green hue"

    before = computed.fetch("before")
    after = computed.fetch("after")

    before.zip(after).each_with_index do |(was, now), index|
      refute_equal was, now,
        "Component #{index} ignored the --nk-color-success override"
    end

    assert_no_severe_console_errors
  end
end
