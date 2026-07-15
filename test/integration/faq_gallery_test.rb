require "test_helper"

class FaqGalleryTest < ActionDispatch::IntegrationTest
  test "FAQ explains the current Nitro Kit decisions" do
    get gallery_faq_path

    assert_response :success
    assert_select "[data-gallery='navigation'] a[aria-current='page'][href='/gallery/faq']", text: "FAQ"
    assert_select "[data-gallery='page'][data-gallery-page='faq']"
    assert_select "h1", text: "Good questions"
    assert_select "[data-gallery='faq-entry']", count: 8
    assert_select "[data-gallery='faq-entry'] h2", text: "Why Phlex?"
    assert_select "[data-gallery='faq-entry'] h2", text: "Why not HTML?"
    assert_select "[data-gallery='faq-entry'] h2", text: "Why is there no class: prop?"
    assert_select "[data-gallery='faq-entry'] h2", text: "How do I change stuff?"
    assert_select "[data-gallery='faq-entry'] h2", text: "Why not Tailwind?"
    assert_select "a[href='/gallery/customize']", text: "configurator"
    assert_select "code", text: "desperately_need_a_class:"
  end

  test "FAQ route is stable" do
    assert_routing(
      { path: "/gallery/faq", method: :get },
      { controller: "gallery/faqs", action: "show" }
    )
  end
end
