require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class ButtonCssTest < ActiveSupport::TestCase
  test "matches Flux base geometry and exposes its neutral treatment" do
    css = button_css

    assert_includes css, "--_nk-button-height: var(--nk-control-height-md)"
    assert_includes css, "--_nk-button-padding: calc(var(--nk-space) * 4)"
    assert_includes css, "--_nk-button-radius: var(--nk-radius-lg)"
    assert_includes css, "--_nk-button-font-size: var(--nk-text-sm)"
    assert_includes css, "--_nk-button-line-height: 1.25rem"
    assert_includes css, "--_nk-button-shadow: 0 1px 2px 0 oklch(0 0 0 / 0.05)"
    assert_includes css, "--_nk-button-background: var(--nk-button-default-background)"
    assert_includes css, "--_nk-button-foreground: var(--nk-button-default-foreground)"
    assert_includes css, "--_nk-button-border: var(--nk-button-default-border)"

    %w[background hover-background foreground border].each do |token|
      assert_includes tokens_css, "--nk-button-default-#{token}:"
    end
  end

  test "shares the default action treatment with the native file selector" do
    css = input_css

    assert_includes css, "background: var(--nk-button-default-background)"
    assert_includes css, "color: var(--nk-button-default-foreground)"
    assert_includes css, "var(--nk-button-default-border)"
    assert_includes css, "background: var(--nk-button-default-hover-background)"
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

  test "spins the owned loading slot and respects reduced motion" do
    css = button_css

    assert_includes css, '[data-nk="button"] > [data-slot="button-spinner"]'
    assert_includes css, "animation: nk-button-spin 1s linear infinite"
    assert_includes css, "@keyframes nk-button-spin"
    assert_includes css, "@media (prefers-reduced-motion: reduce)"
    assert_includes css, "animation: none"
  end

  private

  def button_css
    NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/components/button.css").read
  end

  def tokens_css
    NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/tokens.css").read
  end

  def input_css
    NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/components/input.css").read
  end
end
