require "application_system_test_case"

class ProductResourceResponsiveTest < ApplicationSystemTestCase
  test "tables scroll with intact actions and shell spacing stays balanced" do
    [ "light", "dark" ].each do |theme|
      [ 1280, 390 ].each do |width|
        resize_viewport(width:, height: 900)
        browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 900, deviceScaleFactor: 1, mobile: false) if chrome?
        visit gallery_preview_path(kind: "composition", slug: "product-resource", example: "product-resource-index", state: "index", theme:)
        assert_selector "#gallery-product-resource-table tbody tr", count: 4
        execute_script(<<~JS)
          const table = document.querySelector('[data-ui="resource-table"]')
          table.querySelector('tbody [data-resource-column="name"] strong').textContent =
            'ProductionCameraWithAnUnusuallyLongUnbrokenIdentifier'
          table.querySelector('tbody [data-nk="badge"]').textContent = 'Awaiting approval'
        JS
        canvas = evaluate_script(<<~JS)
          (() => {
            const shell = document.querySelector('[data-ui="inset-workspace"]')
            const s = shell.getBoundingClientRect()
            const r = shell.querySelector('[data-slot="app-shell-sidebar"]').getBoundingClientRect()
            const m = shell.querySelector('[data-slot="app-shell-main"]').getBoundingClientRect()
            const t = shell.querySelector('[data-slot="app-shell-topbar"]').getBoundingClientRect()
            return { gaps: [t.top-s.top, s.right-m.right, s.bottom-m.bottom, m.left-r.right], left: m.left, right: m.right, height: s.height }
          })()
        JS
        assert_in_delta 900, canvas.fetch("height"), 1
        if width == 390
          assert_in_delta 0, canvas.fetch("left"), 1
          assert_in_delta width, canvas.fetch("right"), 1
        else
          canvas.fetch("gaps").zip([ 12, 12, 12, 0 ]).each { |actual, expected| assert_in_delta expected, actual, 1 }
        end
        table = find('[data-ui="resource-table"]')
        assert_selector '[data-resource-column="secondary"]', minimum: 2
        header = evaluate_script(<<~JS)
          (() => {
            const shell = document.querySelector('[data-ui="inset-workspace"]')
            const bar = shell.querySelector('[data-slot="app-shell-topbar"]')
            const style = getComputedStyle(bar)
            const title = bar.querySelector('h1').getBoundingClientRect()
            const action = bar.querySelector('a').getBoundingClientRect()
            const trigger = shell.querySelector('[data-slot="app-shell-mobile-trigger"]').getBoundingClientRect()
            const nav = shell.querySelector('[data-slot="app-navigation-body"]')
            const item = nav.querySelector('[aria-current]').getBoundingClientRect()
            const main = shell.querySelector('[data-slot="app-shell-main"]').getBoundingClientRect()
            return { padding: [style.paddingTop, style.paddingRight, style.paddingBottom, style.paddingLeft].map(parseFloat),
              brand: getComputedStyle(shell.querySelector('[data-slot="app-shell-brand"]')).display,
              titleLeft: title.left, titleMiddle: (title.top+title.bottom)/2,
              actionRight: action.right, actionMiddle: (action.top+action.bottom)/2, triggerRight: trigger.right,
              railGutters: [item.left, main.left-item.right] }
          })()
        JS
        if width == 390
          assert_equal "none", header.fetch("brand")
          assert_in_delta header.fetch("triggerRight") + 8, header.fetch("titleLeft"), 1
          assert_in_delta header.fetch("titleMiddle"), header.fetch("actionMiddle"), 1
          assert_in_delta width - 12, header.fetch("actionRight"), 1
        else
          header.fetch("padding").each { assert_in_delta 24, _1, 1 }
          assert_in_delta(*header.fetch("railGutters"), 1)
        end
        geometry = evaluate_script(<<~JS, table)
          (() => {
          const table = arguments[0]
          const rect = table.getBoundingClientRect()
          return {
            pageWidth: document.documentElement.scrollWidth, viewport: innerWidth, left: rect.left, right: rect.right,
            overflow: table.scrollWidth - table.clientWidth,
            overflowX: getComputedStyle(table).overflowX,
            contentRight: rect.left + table.scrollWidth,
            actions: Array.from(table.querySelectorAll('tbody a')).map(link => {
              const r = link.getBoundingClientRect()
              return { left: r.left, right: r.right, width: r.width, height: r.height, top: r.top }
            })
          }
          })()
        JS
        assert_equal width, geometry.fetch("viewport")
        assert_equal "scroll", geometry.fetch("overflowX")
        assert_operator geometry.fetch("pageWidth"), :<=, width
        assert_operator geometry.fetch("overflow"), :>, 0 if width == 390
        assert_operator geometry.fetch("left"), :>=, 0
        assert_operator geometry.fetch("right"), :<=, width
        assert_equal 8, geometry.fetch("actions").size
        geometry.fetch("actions").each do |action|
          assert_operator action.fetch("left"), :>=, geometry.fetch("left")
          assert_operator action.fetch("right"), :<=, geometry.fetch("contentRight")
          assert_operator action.fetch("width"), :>=, 28
          assert_operator action.fetch("height"), :>=, 28
        end
        geometry.fetch("actions").each_slice(2) do |view, edit|
          assert_in_delta view.fetch("top"), edit.fetch("top"), 1
          assert_operator edit.fetch("left"), :>=, view.fetch("right")
        end
        if width == 390
          execute_script("arguments[0].scrollLeft = arguments[0].scrollWidth", table)
          assert_operator evaluate_script("arguments[0].scrollLeft", table), :>, 0
        end
        save_screenshot(Rails.root.join("tmp/screenshots/resource-table-#{width}-#{theme}.png"))
      end
    end
  end
end
