require "test_helper"

class SettingsLayoutCssTest < ActiveSupport::TestCase
  CURRENT_SELECTOR = ':where( [data-nk="settings-layout"] ' \
    '[data-slot="settings-layout-item-link"][data-state="current"] )'.freeze

  test "navigation items keep a compact row" do
    [ source_css, bundle_section ].each do |css|
      assert_match(/min-block-size: var\(--nk-control-height-sm\);/, css)
      assert_match(/line-height: var\(--nk-leading-tight\);/, css)
      refute_match(/var\(--nk-control-height-md\)/, css)
    end
  end

  test "the current item is marked by emphasis and an indicator, never a filled block" do
    [ source_css, bundle_section ].each do |css|
      assert_includes css, CURRENT_SELECTOR
      declarations = css.split(CURRENT_SELECTOR).last[/\{(.*?)\}/, 1]

      assert_match(/border-inline-start-color: var\(--nk-color-primary\);/, declarations)
      assert_match(/font-weight: var\(--nk-font-weight-semibold\);/, declarations)
      refute_match(/background/, declarations)
    end
  end

  private

  # Selectors wrap across lines in the authored stylesheet, so both sources are
  # compared with their whitespace collapsed.
  def source_css
    @source_css ||= normalize(
      Rails.root.join("../../src/stylesheets/nitro_kit/components/settings_layout.css").read
    )
  end

  def bundle_section
    @bundle_section ||= begin
      bundle = Rails.root.join("../../app/assets/stylesheets/nitro_kit.css").read
      marker = "/* Source: src/stylesheets/nitro_kit/components/settings_layout.css */"

      assert_includes bundle, marker
      normalize(bundle.split(marker).last.split("/* Source:").first)
    end
  end

  def normalize(css)
    css.gsub(/\s+/, " ")
  end
end
