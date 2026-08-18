require "test_helper"

class CommandPaletteCssTest < ActiveSupport::TestCase
  test "ships the trigger panel results and reduced-motion treatment" do
    selectors = %w[
      command-palette-trigger
      command-palette-shortcut
      command-palette-panel
      command-palette-input
      command-palette-destination
      command-palette-empty
    ]

    selectors.each do |slot|
      selector = %(data-slot="#{slot}")
      assert_includes source_css, selector
    end
    assert_includes source_css, "@media (prefers-reduced-motion: reduce)"
    assert_includes source_css, '[data-nk="command-palette-results"]'
    assert_includes source_css, "max-block-size: min(36rem, calc(100dvh - (var(--nk-space) * 8)))"
    assert_includes source_css, "margin-block: 12dvh auto"
    refute_match(/(?<!max-)block-size: min\(36rem/, source_css,
      "the panel hugs its results below the cap instead of holding a fixed height")
    refute_includes source_css, "transition: all"
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/command_palette.css"
    ).read
  end
end
