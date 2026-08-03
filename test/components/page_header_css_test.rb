require "test_helper"

class PageHeaderCssTest < ActiveSupport::TestCase
  test "actions align with the top edge of the trailing column" do
    selector = ':where([data-nk="page-header"] > [data-slot="page-header-actions"])'
    placement = /grid-column: 2;\s+grid-row: 1;\s+justify-self: end;\s+align-self: start;/

    assert_includes source_css, selector
    assert_match placement, source_css
  end

  test "the eyebrow is quiet supporting text rather than a small-caps label" do
    rule = ':where([data-nk="page-header"] > [data-slot="page-header-eyebrow"])'

    assert_includes source_css, rule
    assert_match(/#{Regexp.escape(rule)}\s*\{[^}]*font-weight: var\(--nk-font-weight-normal\);/m, source_css)
    refute_match(/text-transform/, source_css)
    refute_match(/letter-spacing/, source_css)
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/page_header.css"
    ).read
  end
end
