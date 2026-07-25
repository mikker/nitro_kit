require "application_system_test_case"

class FaqTest < ApplicationSystemTestCase
  test "FAQ stays readable on a narrow screen" do
    resize_viewport(width: 390, height: 844)
    visit gallery_faq_path

    assert_current_path gallery_faq_path
    assert_selector "[data-gallery='page'][data-gallery-page='faq']"
    assert_selector "[data-gallery='faq-entry']", count: 8
    assert_selector "[data-gallery='navigation'] a[aria-current='page']", text: "FAQ"

    widths = evaluate_script(<<~JAVASCRIPT)
      ({
        client: document.documentElement.clientWidth,
        scroll: Math.max(document.documentElement.scrollWidth, document.body.scrollWidth)
      })
    JAVASCRIPT

    assert_operator widths.fetch("scroll"), :<=, widths.fetch("client") + 1
    assert_no_severe_console_errors(context: gallery_faq_path)
  end
end
