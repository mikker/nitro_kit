require "application_system_test_case"

class AppShellAnimationTest < ApplicationSystemTestCase
  test "pin transitions keep the panel track highlight and icons synchronized" do
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "no-preference" } ]) if chrome?
    [ "app-shell-sidebar", "app-shell-inset-collapsible" ].each do |example|
      visit gallery_preview_path(kind: "component", slug: "app-shell", example:)
      assert_selector "[data-nk='app-shell'][data-enhanced]"
      [ false, true ].each do |pinned|
        if pinned
          find("[data-slot='app-shell-main']").hover
          pin = find("[data-slot='app-shell-sidebar-toggle']")
          pin.hover
          execute_script("arguments[0].focus()", pin)
          wait_until do
            evaluate_script("document.querySelector('[data-nk=app-shell]').getAnimations({subtree: true}).every(animation => animation.playState !== 'running')")
          end
          assert_in_delta 64, evaluate_script("document.querySelector('[data-slot=app-shell-sidebar]').getBoundingClientRect().width"), 1
        end
        target_width = pinned ? 208 : 64
        start_recording_motion(pinned:, width: target_width)
        find("[data-slot='app-shell-sidebar-toggle']").click
        wait_until { evaluate_script("window.sidebarFramesDone") }
        frames = evaluate_script("window.sidebarFrames")
        moving = frames.select { |frame| frame.fetch("width").between?(65, 207) }
        assert_predicate moving, :present?, "Expected intermediate animation frames for #{example}, pinned: #{pinned}"
        moving.each do |frame|
          assert_in_delta frame.fetch("width"), frame.fetch("main"), 1
          assert_in_delta frame.fetch("width") - 24, frame.fetch("item"), 1.1
          assert_in_delta frames.first.fetch("icon"), frame.fetch("icon"), 0.5
        end
        assert_in_delta target_width, frames.last.fetch("main"), 1
      end
    end
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", features: []) if chrome?
  end

  test "reduced motion settles the track panel and highlight together" do
    skip "Media emulation requires Chrome" unless chrome?
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])
    visit gallery_preview_path(kind: "component", slug: "app-shell", example: "app-shell-inset-collapsible")
    assert_selector "[data-nk='app-shell'][data-enhanced]"
    durations = evaluate_script(<<~JS)
      (() => {
        const shell = document.querySelector('[data-nk="app-shell"]')
        return [shell, shell.querySelector('[data-slot="app-shell-sidebar"]'),
          shell.querySelector('[data-slot="app-navigation-item-link"]')]
          .map(element => parseFloat(getComputedStyle(element).transitionDuration))
      })()
    JS
    durations.each { |duration| assert_operator duration, :<=, 0.001 }
    find("[data-slot='app-shell-sidebar-toggle']").click
    wait_until { evaluate_script("document.querySelector('[data-slot=app-shell-sidebar]').getBoundingClientRect().width < 65") }
    assert_in_delta 64, evaluate_script(<<~JS), 1
      (() => {
        const shell = document.querySelector('[data-nk="app-shell"]')
        return shell.querySelector('[data-slot="app-shell-main"]').getBoundingClientRect().left-shell.getBoundingClientRect().left
      })()
    JS
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", features: []) if chrome?
  end

  private

  def start_recording_motion(pinned:, width:)
    execute_script(<<~JS, pinned, width)
      const targetPinned = arguments[0], targetWidth = arguments[1]
      const shell = document.querySelector('[data-nk="app-shell"]')
      const sidebar = shell.querySelector('[data-slot="app-shell-sidebar"]')
      const main = shell.querySelector('[data-slot="app-shell-main"]')
      const item = shell.querySelector('[data-slot="app-navigation-item-link"]')
      const icon = item.querySelector('[data-slot="app-navigation-item-icon"]')
      window.sidebarFrames = []
      window.sidebarFramesDone = false
      function sample() {
        const origin = shell.getBoundingClientRect().left
        const width = sidebar.getBoundingClientRect().width
        const pinned = shell.getAttribute('data-nk--app-shell-pinned-value') === 'true'
        window.sidebarFrames.push({ pinned, width,
          main: main.getBoundingClientRect().left-origin,
          item: item.getBoundingClientRect().width,
          icon: icon.getBoundingClientRect().left-origin })
        if ((pinned === targetPinned && Math.abs(width-targetWidth) < 0.1) || window.sidebarFrames.length >= 120) {
          window.sidebarFramesDone = true
        } else {
          requestAnimationFrame(sample)
        }
      }
      sample()
    JS
  end
end
