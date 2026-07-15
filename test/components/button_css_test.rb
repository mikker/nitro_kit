require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class ButtonCssTest < ActiveSupport::TestCase
  test "matches Flux base geometry and neutral treatment" do
    css = button_css

    assert_includes css, "--_nk-button-height: var(--nk-control-height-md)"
    assert_includes css, "--_nk-button-padding: calc(var(--nk-space) * 4)"
    assert_includes css, "--_nk-button-radius: var(--nk-radius-lg)"
    assert_includes css, "--_nk-button-font-size: var(--nk-text-sm)"
    assert_includes css, "--_nk-button-line-height: 1.25rem"
    assert_includes css, "--_nk-button-shadow: 0 1px 2px 0 oklch(0 0 0 / 0.05)"
    assert_includes css, "oklch(0.871 0.006 286.286 / 0.8)"
  end

  test "matches Flux primary destructive and ghost treatments" do
    css = button_css

    assert_includes css, "--_nk-button-shadow: inset 0 1px oklch(1 0 0 / 0.2)"
    assert_includes css, "--_nk-button-background: var(--nk-color-danger)"
    assert_includes css, "--_nk-button-hover-background: var(--nk-color-danger-hover)"
    assert_includes css, "oklch(0.274 0.006 286.033 / 0.05)"
    assert_includes css, "oklch(1 0 0 / 0.15)"
    assert_includes tokens_css, "oklch(0.577 0.245 27.325)"
    assert_includes tokens_css, "oklch(0.637 0.237 25.331)"
  end

  test "matches Flux compact sizes icon padding and disabled state" do
    css = button_css

    assert_includes css, "--_nk-button-height: calc(var(--nk-space) * 8)"
    assert_includes css, "--_nk-button-height: var(--nk-control-height-xs)"
    assert_includes css, ':not(:has(> [data-slot="button-label"]))'
    assert_includes css, "opacity: 0.75"
    refute_includes css, "scale("
    refute_includes css, "transition:"
  end

  private

  def button_css
    NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/components/button.css").read
  end

  def tokens_css
    NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/tokens.css").read
  end
end
