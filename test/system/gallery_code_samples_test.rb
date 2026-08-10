require "application_system_test_case"

class GalleryCodeSamplesTest < ApplicationSystemTestCase
  test "code tabs expose exact highlighted Ruby and copy it with visible status" do
    path = gallery_component_path("button")
    visit path

    root = "#example-button-content-combinations-presentation"
    code_tab = "#{root}-code-tab"
    code_panel = "#{root}-code-panel"
    code_sample = "#example-button-content-combinations-code"
    source = "#{code_sample} [data-gallery='code-source']"

    assert_selector "#{code_panel}[hidden]:not([aria-hidden])", visible: :all
    find(code_tab).click

    assert_selector "#{code_tab}[aria-selected='true'][data-state='active']"
    assert_selector "#{code_panel}:not([hidden])[aria-hidden='false']"

    execute_script(<<~JAVASCRIPT)
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText(text) {
            window.__galleryCopiedText = text
            return Promise.resolve()
          }
        }
      })
    JAVASCRIPT

    expected_source = evaluate_script("arguments[0].textContent", find(source))
    find("#{code_sample}-copy").click

    assert_selector "#{code_sample}[data-gallery-code-state='copied']"
    assert_selector "#{code_sample}-copy-status", text: "Copied to clipboard"
    assert_equal expected_source, evaluate_script("window.__galleryCopiedText")

    execute_script(<<~JAVASCRIPT)
      navigator.clipboard.writeText = () => Promise.reject(new Error("Clipboard unavailable"))
    JAVASCRIPT
    find("#{code_sample}-copy").click

    assert_selector "#{code_sample}[data-gallery-code-state='error']"
    assert_selector "#{code_sample}-copy-status", text: "Could not copy"

    resize_viewport(width: 390, height: 844)
    execute_script("arguments[0].scrollIntoView({ block: 'center' })", find(code_sample))
    geometry = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const toolbar = document.querySelector("#{code_sample} [data-gallery='code-toolbar']")
        const button = document.querySelector("#{code_sample}-copy")
        const toolbarRect = toolbar.getBoundingClientRect()
        const buttonRect = button.getBoundingClientRect()

        return {
          buttonLeft: buttonRect.left,
          buttonRight: buttonRect.right,
          toolbarLeft: toolbarRect.left,
          toolbarRight: toolbarRect.right,
          documentWidth: document.documentElement.scrollWidth,
          viewportWidth: document.documentElement.clientWidth
        }
      })()
    JAVASCRIPT

    assert_operator geometry.fetch("buttonLeft"), :>=, geometry.fetch("toolbarLeft")
    assert_operator geometry.fetch("buttonRight"), :<=, geometry.fetch("toolbarRight")
    assert_operator geometry.fetch("documentWidth"), :<=, geometry.fetch("viewportWidth")

    disconnected = evaluate_async_script(<<~JAVASCRIPT)
      const done = arguments[0]
      const sample = document.querySelector("#{code_sample}")
      const status = document.querySelector("#{code_sample}-copy-status")
      const button = document.querySelector("#{code_sample}-copy")
      let finishCopy

      status.textContent = ""
      delete sample.dataset.galleryCodeState
      navigator.clipboard.writeText = () => new Promise((resolve) => { finishCopy = resolve })

      button.click()
      sample.remove()

      setTimeout(() => {
        finishCopy()
        setTimeout(() => done({ status: status.textContent, state: sample.dataset.galleryCodeState }), 0)
      }, 0)
    JAVASCRIPT

    assert_equal "", disconnected.fetch("status")
    assert_nil disconnected["state"]
    assert_no_severe_console_errors(context: path)
  end
end
