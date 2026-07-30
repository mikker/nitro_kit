require "test_helper"

class BadgeCssTest < ActiveSupport::TestCase
  test "a badge never wraps, label and all" do
    root = ':where([data-nk="badge"])'
    label = ':where([data-nk="badge"] > [data-slot="badge-label"])'

    assert_match(/#{Regexp.escape(root)}\s*\{[^}]*white-space: nowrap;/, source_css)
    assert_match(/#{Regexp.escape(label)}\s*\{[^}]*white-space: nowrap;/, source_css)
    assert_match(/#{Regexp.escape(label)}\s*\{[^}]*text-overflow: ellipsis;/, source_css)
  end

  test "a nested icon joins the label line instead of breaking it" do
    rule = <<~CSS.strip
      :where([data-nk="badge"] [data-nk="icon"]) {
          display: inline-block;
          flex: none;
          vertical-align: -0.125em;
        }
    CSS

    assert_includes source_css, rule
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/badge.css"
    ).read
  end
end
