require "test_helper"

class SettingsSectionCssTest < ActiveSupport::TestCase
  STYLESHEET = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/settings_section.css")

  test "uses a plain responsive section instead of a card surface" do
    css = STYLESHEET.read

    assert_includes css, "grid-template-columns: minmax(10rem, 14rem) minmax(0, 1fr)"
    assert_includes css, "grid-column: 2"
    assert_includes css, "@media (width < 48rem)"
    assert_includes css, "grid-column: 1"
    assert_includes css, '[data-nk="settings-section"] + [data-nk="settings-section"]'
    refute_match(/\[data-nk="settings-section"\]\) \{[^}]*background:/m, css)
    refute_match(/\[data-nk="settings-section"\]\) \{[^}]*border-radius:/m, css)
  end
end
