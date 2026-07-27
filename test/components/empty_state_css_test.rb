require "test_helper"

class EmptyStateCssTest < ActiveSupport::TestCase
  test "the default keeps the dashed frame" do
    rule = ':where([data-nk="empty-state"])'

    assert_match(
      /#{Regexp.escape(rule)}\s*\{[^}]*border: var\(--nk-border-width\) dashed var\(--nk-color-border\);/,
      bundle_css
    )
  end

  test "the borderless variant drops the frame and the fill" do
    rule = <<~CSS.strip
      :where([data-nk="empty-state"][data-variant="borderless"]) {
          background: none;
          border-color: transparent;
        }
    CSS

    assert_includes source_css, rule
    assert_includes bundle_css, rule
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/empty_state.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
