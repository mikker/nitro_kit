require "application_system_test_case"

class GalleryResponsivePreviewTest < ApplicationSystemTestCase
  test "preview measures when its hidden tab becomes visible" do
    visit gallery_component_path("grid")

    example = find("[data-gallery-example='grid-card-collection']")
    example.find("[role='tab']", text: "Responsive").click
    viewport = example.find("[data-gallery='responsive-preview']")

    assert_selector viewport, "output", text: /\d+ px · (base|sm|md|lg|xl|2xl)/
    assert_operator viewport.find("input[type='range']")[:max].to_i, :>, 0
  end

  test "responsive iframe crosses a real Nitro viewport breakpoint" do
    visit gallery_component_path("flex")

    example = find("[data-gallery-example='flex-responsive-arrangement']")
    example.find("[role='tab']", text: "Responsive").click
    viewport = example.find("[data-gallery='responsive-preview']")
    iframe = viewport.find("iframe[data-gallery='preview-iframe']")
    assert_no_severe_console_errors(context: "responsive preview controller")

    viewport.select("Below md · 767 px", from: "example-flex-responsive-arrangement-preview-preset")
    assert_text "767 px · sm"
    within_frame iframe do
      assert_selector "#gallery-flex-responsive[data-dir='col md:row']"
      assert_equal "column", evaluate_script("getComputedStyle(arguments[0]).flexDirection", find("#gallery-flex-responsive"))
      assert_equal 767, evaluate_script("window.innerWidth")
    end

    viewport.select("md · 768 px", from: "example-flex-responsive-arrangement-preview-preset")
    assert_text "768 px · md"
    within_frame iframe do
      assert_equal "row", evaluate_script("getComputedStyle(arguments[0]).flexDirection", find("#gallery-flex-responsive"))
      assert_equal 768, evaluate_script("window.innerWidth")
    end
  end

  test "range handle keyboard reset and full controls share one width" do
    visit gallery_component_path("flex")

    example = find("[data-gallery-example='flex-responsive-arrangement']")
    example.find("[role='tab']", text: "Responsive").click
    viewport = example.find("[data-gallery='responsive-preview']")
    range = viewport.find("input[type='range']")
    handle = viewport.find("[data-gallery='preview-handle']")
    assert_no_severe_console_errors(context: "responsive preview controls")

    execute_script("arguments[0].focus()", range)
    range.send_keys(:home)
    assert_text "320 px · base"

    execute_script("arguments[0].focus()", handle)
    handle.send_keys(:arrow_right)
    assert_text "336 px · base"
    assert_equal "336", handle["aria-valuenow"]

    viewport.find("button", text: "Full width").click
    assert_text(/px · (md|lg|xl|2xl) · full/)
    viewport.find("button", text: "Reset").click
    assert_text(/px · (md|lg|xl|2xl) · full/)
    assert viewport.find("button", text: "Reset").disabled?
  end
end
