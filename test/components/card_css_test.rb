require "test_helper"

class CardCssTest < ActiveSupport::TestCase
  test "the bleeding region clips instead of the card itself" do
    root = ':where([data-nk="card"])'
    full = ':where([data-nk="card"] > [data-slot="card-full"])'

    refute_match(/#{Regexp.escape(root)}\s*\{[^}]*overflow:/, source_css)
    assert_match(/#{Regexp.escape(full)}\s*\{[^}]*overflow: hidden;/, source_css)
  end

  test "a leading full-width region takes the card's own corner radius" do
    rule = <<~CSS.strip
      :where([data-nk="card"] > [data-slot="card-full"]:first-child) {
          margin-block-start: calc(var(--_nk-card-padding) * -1);
          border-start-start-radius: calc(
            var(--_nk-card-radius) - var(--nk-border-width)
          );
          border-start-end-radius: calc(var(--_nk-card-radius) - var(--nk-border-width));
        }
    CSS

    assert_includes source_css, normalize(rule)
  end

  test "sizes coordinate padding gaps and corners without changing the default" do
    {
      nil => [ 6, 4, "var(--nk-radius-xl)" ],
      "sm" => [ 4, 3, "var(--nk-radius-lg)" ],
      "lg" => [ 8, 6, "calc(var(--nk-radius-xl) + var(--nk-space))" ]
    }.each do |size, (padding, gap, radius)|
      selector = size ? %(:where([data-nk="card"][data-size="#{size}"])) : %(:where([data-nk="card"]))
      rule = source_css.match(/#{Regexp.escape(selector)}\s*\{([^}]+)\}/)[1]

      assert_includes rule, "--_nk-card-padding: calc(var(--nk-space) * #{padding});"
      assert_includes rule, "--_nk-card-gap: calc(var(--nk-space) * #{gap});"
      assert_includes rule, "--_nk-card-radius: #{radius};"
    end

    assert_includes source_css, "gap: var(--_nk-card-gap);"
    assert_includes source_css, "border-radius: var(--_nk-card-radius);"
    refute_match(/var\(--nk-radius-lg\) -/, source_css)
  end

  test "muted tints without a shadow" do
    selector = ':where([data-nk="card"][data-variant="muted"])'
    rule = source_css.match(/#{Regexp.escape(selector)}\s*\{([^}]+)\}/)[1]

    assert_includes rule, "box-shadow: none;"
    assert_includes rule, "color-mix("
  end

  test "edge sections set apart by a divider get even block spacing" do
    assert_includes source_css, "padding-block-start: var(--_nk-card-gap);"
    assert_includes source_css, "padding-block-end: var(--_nk-card-gap);"
    assert_includes source_css, %(+ :last-child:not([data-slot="card-full"]):not([data-slot="card-divider"]))
  end

  test "tables bleeding to the edges keep the card gutter" do
    assert_match(/\[data-nk="table"\] \[data-slot="table-cell"\]:first-child\s*\)\s*\{\s*padding-inline-start: var\(--_nk-card-padding\);/m, source_css)
    assert_match(/\[data-nk="table"\] \[data-slot="table-cell"\]:last-child\s*\)\s*\{\s*padding-inline-end: var\(--_nk-card-padding\);/m, source_css)
  end

  test "outline removes fill and shadow but retains the shared border" do
    selector = ':where([data-nk="card"][data-variant="outline"])'
    rule = source_css.match(/#{Regexp.escape(selector)}\s*\{([^}]+)\}/)[1]

    assert_includes rule, "background: transparent;"
    assert_includes rule, "box-shadow: none;"
    refute_includes rule, "border:"
    assert_includes source_css, "border: var(--nk-border-width) solid var(--nk-color-border);"
  end

  test "footer text can shrink below a long unbroken word's intrinsic width" do
    selector = ':where([data-nk="card"] > [data-slot="card-footer"])'
    rule = source_css.match(/#{Regexp.escape(selector)}\s*\{([^}]+)\}/)[1]

    assert_includes rule, "overflow-wrap: anywhere;"
    assert_includes rule, "flex-wrap: wrap;"
  end

  test "full-width media drops its own corner radius" do
    rule = <<~CSS.strip
      :where(
            [data-nk="card"]
              > [data-slot="card-full"]
              :is(img, [data-nk="progressive-image"])
          ) {
          border-radius: 0;
        }
    CSS

    assert_includes source_css, normalize(rule)
  end

  private

  # Compare rules independently of how the formatter wraps selectors and values.
  def source_css
    @source_css ||= normalize(Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/card.css"
    ).read)
  end

  def normalize(css)
    css.gsub(/\s+/, " ").gsub(/\(\s+/, "(").gsub(/\s+\)/, ")")
  end
end
