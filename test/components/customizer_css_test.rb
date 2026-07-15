require "test_helper"

class CustomizerCssTest < ActiveSupport::TestCase
  STYLESHEET = NitroKit::Engine.root.join("test/dummy/app/assets/stylesheets/customize.css")

  test "scopes studio structure to stable gallery markers" do
    css = STYLESHEET.read

    assert_includes css, "@layer gallery"
    assert_includes css, '[data-gallery-page="customize"]'
    assert_includes css, '[data-gallery="theme-preview"]'
    assert_includes css, '[data-gallery="customizer-controls"]'
    assert_includes css, '[data-gallery="customizer-export"]'
    assert_includes css, ":where("
    refute_includes css, "--_nk-"
    refute_includes css, "!important"
    refute_includes css, "transition: all"
  end

  test "keeps narrow controls reachable as a compact horizontal strip" do
    css = STYLESHEET.read
    narrow = css[/@media \(max-width: 48rem\)(?<body>.*)@media \(prefers-reduced-motion/m, :body]

    assert_includes narrow, "grid-auto-flow: column"
    assert_includes narrow, "grid-auto-columns: minmax(13rem, 78vw)"
    assert_includes narrow, "overflow-x: auto"
    assert_includes narrow, "scroll-snap-type: inline mandatory"
    assert_includes css, "min-block-size: 2.5rem"
    assert_includes css, "@media (prefers-reduced-motion: reduce)"
  end

  test "keeps every named accent and neutral swatch aligned to its token map" do
    css = STYLESHEET.read.gsub(/\s+/, " ")

    Gallery::ThemePreset::CHOICES.fetch(:accent).each do |choice|
      value = Gallery::ThemePreset::TOKEN_MAPS.dig(
        :accent,
        choice,
        :light,
        "--nk-color-primary"
      )
      selector = "[data-gallery-swatch-kind=\"accent\"][data-gallery-swatch=\"#{choice}\"]"

      assert_includes css, selector
      assert_match(/#{Regexp.escape(selector)} .*?background: #{Regexp.escape(value)};/, css)
    end

    Gallery::ThemePreset::CHOICES.fetch(:neutral).each do |choice|
      value = Gallery::ThemePreset::TOKEN_MAPS.dig(
        :neutral,
        choice,
        :light,
        "--nk-color-neutral"
      )
      selector = "[data-gallery-swatch-kind=\"neutral\"][data-gallery-swatch=\"#{choice}\"]"

      assert_includes css, selector
      assert_match(/#{Regexp.escape(selector)} .*?background: #{Regexp.escape(value)};/, css)
    end
  end
end
