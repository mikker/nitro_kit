require "test_helper"

class ResetCssTest < ActiveSupport::TestCase
  test "the universal rule zeroes box model for the whole page" do
    assert_rule(
      ":where(*),\n  ::before,\n  ::after,\n  ::backdrop,\n  ::file-selector-button",
      /box-sizing: border-box;\s*margin: 0;\s*padding: 0;\s*border: 0 solid;/
    )
  end

  test "the document root carries the Nitro font stack" do
    assert_rule(
      ":where(html, :host)",
      /font-family: var\(--nk-font-sans\);\s*line-height: var\(--nk-leading-normal\);/
    )
  end

  test "form controls inherit typography and color" do
    assert_rule(
      ":where(button, input, select, optgroup, textarea),\n  ::file-selector-button",
      /font: inherit;/
    )
  end

  test "list markers are stripped only from Nitro-owned lists" do
    scoped = /
      :where\(\s*
      ol\[data-nk\],\s*
      ul\[data-nk\],\s*
      menu\[data-nk\],\s*
      \[data-nk\]\ :is\(ol,\ ul,\ menu\)\[data-slot\]\s*
      \)\s*\{\s*list-style:\ none;
    /x

    assert_match scoped, source_css
    assert_match scoped, bundle_css

    refute_match(/^\s*:where\(ol, ul, menu\)/, source_css)
    refute_match(/^\s*:where\(ol, ul, menu\)/, bundle_css)
  end

  private

  def assert_rule(selector, body)
    assert_includes source_css, selector
    assert_includes bundle_css, selector
    assert_match(/#{Regexp.escape(selector)}\s*\{\s*#{body.source}/, source_css)
    assert_match(/#{Regexp.escape(selector)}\s*\{\s*#{body.source}/, bundle_css)
  end

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/reset.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
