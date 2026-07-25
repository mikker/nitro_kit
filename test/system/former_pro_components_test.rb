require "application_system_test_case"

class FormerProComponentsTest < ApplicationSystemTestCase
  test "progressive images settle loaded empty and error states without duplicate accessible images" do
    path = gallery_component_path("progressive-image")
    visit path

    assert_selector "#gallery-progressive-image-loaded[data-state='loaded'][aria-busy='false']"
    assert_selector "#gallery-progressive-image-loaded [data-slot='progressive-image-placeholder'][alt=''][aria-hidden='true']", visible: :all
    assert_selector "#gallery-progressive-image-loaded [data-slot='progressive-image-image'][alt='Abstract indigo workspace illustration']"
    assert_selector "#gallery-progressive-image-loaded img:not([alt=''])", count: 1

    assert_selector "#gallery-progressive-image-empty[data-state='empty']:not([data-controller])"
    assert_selector "#gallery-progressive-image-empty [data-slot='progressive-image-fallback']", text: "Image unavailable"

    execute_script(
      "arguments[0].scrollIntoView({ block: 'center' })",
      find("#gallery-progressive-image-error")
    )
    assert_selector "#gallery-progressive-image-error[data-state='error'][aria-busy='false']"
    assert_selector "#gallery-progressive-image-error [data-slot='progressive-image-fallback']:not([hidden])", text: "Image unavailable"
    assert_selector "#gallery-progressive-image-error [data-slot='progressive-image-image']:not([aria-hidden])", visible: :all

    controller = evaluate_script(<<~JAVASCRIPT)
      window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector("#gallery-progressive-image-loaded"),
        "nk--progressive-image"
      ) !== null
    JAVASCRIPT
    assert controller, "Expected the progressive image controller to connect"

    assert_no_severe_console_errors(context: path)
  end

  test "Turbo Drive reconnects progressive images and details remain server rendered" do
    visit gallery_component_path("progressive-image")
    assert_selector "#gallery-progressive-image-loaded[data-state='loaded']"

    within("[data-gallery='sidebar']") { click_link("Details table") }

    assert_current_path gallery_component_path("details-table")
    assert_selector "#gallery-details-table-profile[data-nk='details-table']", count: 1
    assert_selector "#gallery-details-table-profile [data-slot='table-row']", count: 7
    assert_selector "#gallery-details-table-values [data-slot='details-table-empty']", text: "Not provided"

    within("[data-gallery='sidebar']") { click_link("Progressive image") }

    assert_current_path gallery_component_path("progressive-image")
    assert_selector "#gallery-progressive-image-loaded[data-state='loaded']", count: 1
    execute_script(
      "arguments[0].scrollIntoView({ block: 'center' })",
      find("#gallery-progressive-image-error")
    )
    assert_selector "#gallery-progressive-image-error[data-state='error']", count: 1
    assert_no_severe_console_errors
  end

  test "the unenhanced full image remains visible when Stimulus disconnects" do
    path = gallery_component_path("progressive-image")
    visit path

    root = "#gallery-progressive-image-loaded"
    assert_selector "#{root}[data-state='loaded'][data-enhanced='true']"

    execute_script("arguments[0].removeAttribute('data-controller')", find(root))
    assert_selector "#{root}:not([data-enhanced])"
    wait_until(message: "progressive image styles did not settle after disconnect") do
      evaluate_script(<<~JAVASCRIPT)
        (() => {
          const root = document.querySelector("#{root}")
          const image = root.querySelector("[data-slot='progressive-image-image']")
          const placeholder = root.querySelector("[data-slot='progressive-image-placeholder']")

          return getComputedStyle(image).opacity === "1" &&
            getComputedStyle(placeholder).opacity === "0"
        })()
      JAVASCRIPT
    end

    visibility = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const root = document.querySelector("#{root}")
        const image = root.querySelector("[data-slot='progressive-image-image']")
        const placeholder = root.querySelector("[data-slot='progressive-image-placeholder']")

        return {
          imageOpacity: getComputedStyle(image).opacity,
          placeholderOpacity: getComputedStyle(placeholder).opacity
        }
      })()
    JAVASCRIPT

    assert_equal "1", visibility.fetch("imageOpacity")
    assert_equal "0", visibility.fetch("placeholderOpacity")
    assert_no_severe_console_errors(context: path)
  end
end
