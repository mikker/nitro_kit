require "test_helper"

class PageHeaderCssTest < ActiveSupport::TestCase
  test "actions take the trailing column without spanning the text rows" do
    selector = ':where([data-nk="page-header"] > [data-slot="page-header-actions"])'
    placement = /grid-column: 2;\s+justify-self: end;\s+align-self: end;/

    [ source_css, bundle_section ].each do |css|
      assert_includes css, selector
      assert_match placement, css
      # A row span resolves against explicit rows this grid never declares, so
      # it collapsed to row one and seated the actions beside the eyebrow.
      refute_match(/grid-row/, css)
    end
  end

  test "the eyebrow is quiet supporting text rather than a small-caps label" do
    rule = ':where([data-nk="page-header"] > [data-slot="page-header-eyebrow"])'

    [ source_css, bundle_section ].each do |css|
      assert_includes css, rule
      assert_match(/#{Regexp.escape(rule)}\s*\{[^}]*font-weight: var\(--nk-font-weight-normal\);/m, css)
      refute_match(/text-transform/, css)
      refute_match(/letter-spacing/, css)
    end
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/page_header.css"
    ).read
  end

  def bundle_section
    @bundle_section ||= begin
      bundle = Rails.root.join("../../app/assets/stylesheets/nitro_kit.css").read
      marker = "/* Source: src/stylesheets/nitro_kit/components/page_header.css */"

      assert_includes bundle, marker
      bundle.split(marker).last.split("/* Source:").first
    end
  end
end
