require "test_helper"

class DialogCssTest < ActiveSupport::TestCase
  test "the structural root does not add a flex or grid item" do
    assert_includes source_css, ':where([data-nk="dialog"])'
    assert_includes source_css, "display: contents"
  end

  test "a non-modal open panel stays in normal flow" do
    rule = ':where([data-nk="dialog"] > [data-slot="dialog-panel"][open]:not(:modal))'

    assert_includes source_css, rule
    assert_includes bundle_css, rule
    assert_match(/#{Regexp.escape(rule)}\s*\{\s*position: static;/, bundle_css)
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/dialog.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
