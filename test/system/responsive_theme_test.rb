require "application_system_test_case"

class ResponsiveThemeTest < ApplicationSystemTestCase
  Viewport = Data.define(:name, :width, :height)
  ReviewCase = Data.define(:kind, :slug, :state, :viewport, :theme, :selector, :probe)

  PHONE = Viewport.new(name: "phone", width: 390, height: 844)
  TABLET = Viewport.new(name: "tablet", width: 768, height: 1024)
  DESKTOP = Viewport.new(name: "desktop", width: 1440, height: 1000)

  REVIEW_CASES = [
    ReviewCase.new(
      kind: :home,
      slug: "home",
      state: nil,
      viewport: PHONE,
      theme: "light",
      selector: "[data-gallery='introduction']",
      probe: :home
    ),
    ReviewCase.new(
      kind: :home,
      slug: "home",
      state: nil,
      viewport: DESKTOP,
      theme: "dark",
      selector: "[data-gallery='introduction']",
      probe: :home
    ),
    ReviewCase.new(
      kind: :component,
      slug: "dialog",
      state: nil,
      viewport: PHONE,
      theme: "dark",
      selector: "#gallery-dialog-remove-member[data-nk='dialog']",
      probe: :dialog
    ),
    ReviewCase.new(
      kind: :component,
      slug: "table",
      state: nil,
      viewport: PHONE,
      theme: "dark",
      selector: "#gallery-table-credentials[data-nk='table']",
      probe: :table
    ),
    ReviewCase.new(
      kind: :component,
      slug: "table",
      state: nil,
      viewport: TABLET,
      theme: "light",
      selector: "#gallery-table-credentials[data-nk='table']",
      probe: :table
    ),
    ReviewCase.new(
      kind: :component,
      slug: "settings-layout",
      state: nil,
      viewport: PHONE,
      theme: "light",
      selector: "#gallery-settings-layout-workspace[data-nk='settings-layout']",
      probe: :settings_layout
    ),
    ReviewCase.new(
      kind: :component,
      slug: "settings-layout",
      state: nil,
      viewport: DESKTOP,
      theme: "dark",
      selector: "#gallery-settings-layout-workspace[data-nk='settings-layout']",
      probe: :settings_layout
    ),
    ReviewCase.new(
      kind: :composition,
      slug: "api-webhooks",
      state: "dense",
      viewport: PHONE,
      theme: "dark",
      selector: "[data-gallery='composition-surface'] [data-nk='page-header']",
      probe: :surface
    ),
    ReviewCase.new(
      kind: :composition,
      slug: "landing",
      state: "long",
      viewport: PHONE,
      theme: "light",
      selector: "[data-gallery='composition-surface'] [data-nk='page-header']",
      probe: :surface
    ),
    ReviewCase.new(
      kind: :composition,
      slug: "account-security",
      state: "mobile",
      viewport: PHONE,
      theme: "dark",
      selector: "[data-nk='auth-shell']",
      probe: :surface
    ),
    ReviewCase.new(
      kind: :composition,
      slug: "checkout",
      state: "payment",
      viewport: PHONE,
      theme: "light",
      selector: "[data-nk='form-section']",
      probe: :surface
    )
  ].freeze

  REVIEW_CASES.each do |review_case|
    test "#{review_case.slug} #{review_case.state || "default"} at #{review_case.viewport.name} in #{review_case.theme}" do
      path = review_path(review_case)
      set_exact_viewport(review_case.viewport)
      visit path

      assert_current_path path
      assert_selector "html[data-gallery='document'][data-theme='#{review_case.theme}']"
      assert_selector page_marker(review_case)
      assert_selector review_case.selector
      assert_no_document_horizontal_overflow
      assert_review_probe(review_case, viewport: review_case.viewport)
      assert_no_severe_console_errors(context: path)
    end
  end

  private
    def set_exact_viewport(viewport)
      resize_viewport(width: viewport.width, height: viewport.height)
      browser.execute_cdp(
        "Emulation.setDeviceMetricsOverride",
        width: viewport.width,
        height: viewport.height,
        deviceScaleFactor: 1,
        mobile: false
      )

      assert_equal [ viewport.width, viewport.height ], evaluate_script("[window.innerWidth, window.innerHeight]")
    end

    def review_path(review_case)
      entry = Gallery::Catalog.fetch!(kind: review_case.kind, slug: review_case.slug)
      path = Gallery::Catalog.path_for(
        entry,
        routes: Rails.application.routes.url_helpers,
        state: review_case.state
      )

      "#{path}?theme=#{review_case.theme}"
    end

    def page_marker(review_case)
      selector = "div[data-gallery='page'][data-gallery-page='#{review_case.slug}']"
      review_case.state ? "#{selector}[data-gallery-state='#{review_case.state}']" : selector
    end

    def assert_no_document_horizontal_overflow
      widths = evaluate_script(<<~JAVASCRIPT)
        ({
          client: document.documentElement.clientWidth,
          scroll: Math.max(document.documentElement.scrollWidth, document.body.scrollWidth)
        })
      JAVASCRIPT

      assert_operator widths.fetch("scroll"), :<=, widths.fetch("client") + 1,
        "Expected document width #{widths.fetch("scroll")}px to fit #{widths.fetch("client")}px viewport"
    end

    def assert_review_probe(review_case, viewport:)
      case review_case.probe
      when :home
        assert_selector "[data-gallery='introduction'] li", count: 8
      when :dialog
        assert_dialog_containment
      when :table
        assert_table_containment
      when :settings_layout
        assert_settings_layout_containment(viewport:)
      when :surface
        assert_horizontally_inside_viewport(review_case.selector)
      end
    end

    def assert_dialog_containment
      root = "#gallery-dialog-remove-member"
      find("#{root} [data-slot='dialog-trigger']").click
      assert_selector "#{root} [data-slot='dialog-panel'][open]"
      assert_inside_viewport "#{root} [data-slot='dialog-panel']"
    end

    def assert_table_containment
      selector = "#gallery-table-credentials"
      assert_horizontally_inside_viewport(selector)

      overflow = evaluate_script("getComputedStyle(arguments[0]).overflowX", find(selector))
      assert_equal "auto", overflow
    end

    def assert_settings_layout_containment(viewport:)
      selector = "#gallery-settings-layout-workspace"
      assert_horizontally_contained "#{selector} > [data-slot='settings-layout-navigation']", by: selector
      assert_horizontally_contained "#{selector} > [data-slot='settings-layout-content']", by: selector

      columns = evaluate_script("getComputedStyle(arguments[0]).gridTemplateColumns", find(selector)).split
      expected_columns = viewport.width <= 768 ? 1 : 2
      assert_equal expected_columns, columns.size
    end

    def assert_inside_viewport(selector)
      bounds = element_bounds(selector)

      assert_operator bounds.fetch("left"), :>=, -1
      assert_operator bounds.fetch("top"), :>=, -1
      assert_operator bounds.fetch("right"), :<=, bounds.fetch("viewportWidth") + 1
      assert_operator bounds.fetch("bottom"), :<=, bounds.fetch("viewportHeight") + 1
    end

    def assert_horizontally_inside_viewport(selector)
      bounds = element_bounds(selector)

      assert_operator bounds.fetch("left"), :>=, -1
      assert_operator bounds.fetch("right"), :<=, bounds.fetch("viewportWidth") + 1
    end

    def assert_horizontally_contained(selector, by:)
      child = element_bounds(selector)
      parent = element_bounds(by)

      assert_operator child.fetch("left"), :>=, parent.fetch("left") - 1
      assert_operator child.fetch("right"), :<=, parent.fetch("right") + 1
    end

    def element_bounds(selector)
      evaluate_script(<<~JAVASCRIPT, find(selector))
        (() => {
          const rect = arguments[0].getBoundingClientRect()

          return {
            left: rect.left,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
            viewportWidth: window.innerWidth,
            viewportHeight: window.innerHeight
          }
        })()
      JAVASCRIPT
    end
end
