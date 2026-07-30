require "test_helper"

class SettingsLayoutCssTest < ActiveSupport::TestCase
  CURRENT_SELECTOR = ':where( [data-nk="settings-layout"] ' \
    '[data-slot="settings-layout-item-link"][data-state="current"] )'.freeze

  test "navigation items keep a compact row" do
    assert_match(/min-block-size: var\(--nk-control-height-sm\);/, source_css)
    assert_match(/line-height: var\(--nk-leading-tight\);/, source_css)
    refute_match(/var\(--nk-control-height-md\)/, source_css)
  end

  test "the current item is marked by emphasis without a decorative edge or filled block" do
    assert_includes source_css, CURRENT_SELECTOR
    declarations = source_css.split(CURRENT_SELECTOR).last[/\{(.*?)\}/, 1]

    assert_match(/font-weight: var\(--nk-font-weight-semibold\);/, declarations)
    refute_match(/border-(?:inline-start|left)/, source_css)
    refute_match(/background/, declarations)
  end

  private

  # Selectors wrap across lines in the authored stylesheet.
  def source_css
    @source_css ||= normalize(
      Rails.root.join("../../src/stylesheets/nitro_kit/components/settings_layout.css").read
    )
  end

  def normalize(css)
    css.gsub(/\s+/, " ")
  end
end
