require "application_system_test_case"

class ApplicationCombinationsTest < ApplicationSystemTestCase
  APPLICATIONS = {
    "application-sidebar" => {
      layout: "sidebar",
      states: %w[populated empty error]
    },
    "application-topbar" => {
      layout: "topbar",
      states: %w[populated loading long]
    },
    "application-hybrid" => {
      layout: "hybrid",
      states: %w[populated missing error]
    }
  }.freeze

  test "complete applications keep their desktop layout and expose an accessible mobile drawer" do
    APPLICATIONS.each do |slug, contract|
      resize_viewport(width: 1200, height: 900)
      path = gallery_composition_path(slug:)
      visit path

      layout = contract.fetch(:layout)
      state = contract.fetch(:states).first
      root = "#gallery-#{layout}-application-#{state}"
      sidebar = "#{root} > [data-slot='app-shell-sidebar']"
      dialog = "#{root} > [data-slot='app-shell-dialog']"
      trigger = "#{root} [data-slot='app-shell-mobile-trigger']"

      assert_selector "#{root}[data-enhanced][data-layout='#{layout}']"
      assert_selector "#{sidebar} > [data-slot='app-shell-navigation'] [data-nk='app-navigation']", count: 1
      assert_desktop_layout(root, layout:)
      assert_document_fits_viewport

      resize_viewport(width: 390, height: 844)

      assert_selector "#{root}[data-state='closed']"
      assert_selector "#{dialog}:not([open])", visible: :all
      assert_equal "none", evaluate_script(
        "getComputedStyle(document.querySelector(arguments[0])).display",
        sidebar
      )
      assert_selector "#{trigger}[aria-expanded='false'][aria-label='Open navigation']"
      assert_mobile_containment(root)
      assert_document_fits_viewport

      find(trigger).click

      assert_selector "#{root}[data-state='open']"
      assert_selector "#{dialog}[open][aria-label='Application navigation'] > [data-slot='app-shell-navigation']"
      assert_equal true, evaluate_script(
        "document.querySelector(arguments[0]).matches(':modal')",
        dialog
      )

      active_element.send_keys(:escape)

      assert_selector "#{root}[data-state='closed']"
      assert_selector "#{dialog}:not([open])", visible: :all
      assert_selector "#{sidebar} > [data-slot='app-shell-navigation']", visible: :all
      assert_no_severe_console_errors(context: path)
    end
  end

  test "a narrow child-route toolbar preserves its title above persistent actions" do
    resize_viewport(width: 390, height: 844)
    visit gallery_composition_path(
      slug: "product-resource",
      state: "active",
      product_id: "product_release_console"
    )

    assert_selector "#gallery-product-resource-back"
    assert_selector "#gallery-product-resource-toolbar-actions [data-nk='button']", count: 2
    assert_selector "#gallery-product-resource-toolbar h1", text: "Release Console"

    geometry = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const toolbar = document.querySelector("#gallery-product-resource-toolbar")
        const leading = toolbar.querySelector('[data-slot="toolbar-leading"]')
        const trailing = toolbar.querySelector('[data-slot="toolbar-trailing"]')
        const title = leading.querySelector("h1")
        const toolbarRect = toolbar.getBoundingClientRect()
        const leadingRect = leading.getBoundingClientRect()
        const trailingRect = trailing.getBoundingClientRect()
        const titleRect = title.getBoundingClientRect()

        return {
          titleWidth: titleRect.width,
          titleInsideLeading:
            titleRect.left >= leadingRect.left - 1 &&
            titleRect.right <= leadingRect.right + 1,
          actionsBelowTitle: leadingRect.bottom <= trailingRect.top + 1,
          childrenInsideToolbar: [leadingRect, trailingRect].every((rect) =>
            rect.left >= toolbarRect.left - 1 &&
            rect.right <= toolbarRect.right + 1 &&
            rect.top >= toolbarRect.top - 1 &&
            rect.bottom <= toolbarRect.bottom + 1
          )
        }
      })()
    JAVASCRIPT

    assert_operator geometry.fetch("titleWidth"), :>, 80
    assert geometry.fetch("titleInsideLeading")
    assert geometry.fetch("actionsBelowTitle")
    assert geometry.fetch("childrenInsideToolbar")
    assert_document_fits_viewport
  end

  private

  def assert_desktop_layout(root, layout:)
    state = computed_shell(root)
    assert_equal "auto", state.fetch("mainOverflowY")

    case layout
    when "sidebar"
      assert_equal "sticky", state.fetch("drawerPosition")
      assert_equal "column", state.fetch("navigationDirection")
      assert_in_delta 0, state.fetch("drawerBottomDelta"), 1
    when "topbar"
      assert_equal "contents", state.fetch("drawerDisplay")
      assert_equal "row", state.fetch("navigationDirection")
      assert_topbar_containment(state)
    when "hybrid"
      assert_equal "sticky", state.fetch("drawerPosition")
      assert_equal "column", state.fetch("navigationDirection")
      assert_equal "flex", state.fetch("topbarDisplay")
      assert_in_delta 0, state.fetch("drawerBottomDelta"), 1
      assert_topbar_containment(state)
    else
      flunk("Unknown application layout: #{layout}")
    end
  end

  def computed_shell(root_selector)
    evaluate_script(<<~JAVASCRIPT, root_selector)
      (() => {
        const root = document.querySelector(arguments[0]);
        const drawer = root.querySelector('[data-slot="app-shell-sidebar"]');
        const navigation = root.querySelector('[data-nk="app-navigation"]');
        const main = root.querySelector('[data-slot="app-shell-main"]');
        const header = root.querySelector('[data-slot="app-shell-header"]');
        const topbar = root.querySelector('[data-slot="app-shell-topbar"]');
        const rootRect = root.getBoundingClientRect();
        const drawerRect = drawer.getBoundingClientRect();
        const headerRect = header.getBoundingClientRect();
        const topbarRect = topbar?.getBoundingClientRect();
        const headerChildrenContained = Array.from(header.children).every((child) => {
          const childRect = child.getBoundingClientRect();
          return childRect.left >= headerRect.left - 1 &&
            childRect.right <= headerRect.right + 1 &&
            childRect.top >= headerRect.top - 1 &&
            childRect.bottom <= headerRect.bottom + 1;
        });
        const topbarChildrenContained = !topbar || Array.from(topbar.children).every((child) => {
          const childRect = child.getBoundingClientRect();
          return childRect.left >= topbarRect.left - 1 &&
            childRect.right <= topbarRect.right + 1 &&
            childRect.top >= topbarRect.top - 1 &&
            childRect.bottom <= topbarRect.bottom + 1;
        });

        return {
          rootScrollWidth: root.scrollWidth,
          rootClientWidth: root.clientWidth,
          drawerDisplay: getComputedStyle(drawer).display,
          drawerPosition: getComputedStyle(drawer).position,
          drawerBottomDelta: drawerRect.bottom - rootRect.bottom,
          navigationDirection: getComputedStyle(navigation).flexDirection,
          mainOverflowY: getComputedStyle(main).overflowY,
          headerScrollHeight: header.scrollHeight,
          headerClientHeight: header.clientHeight,
          headerChildrenContained,
          topbarDisplay: topbar ? getComputedStyle(topbar).display : null,
          topbarClientHeight: topbar?.clientHeight ?? 0,
          topbarScrollHeight: topbar?.scrollHeight ?? 0,
          topbarChildrenContained,
        };
      })()
    JAVASCRIPT
  end

  def assert_mobile_containment(root)
    state = computed_shell(root)

    assert_equal "auto", state.fetch("mainOverflowY")
    assert_operator state.fetch("rootScrollWidth"), :<=, state.fetch("rootClientWidth")
    assert_operator state.fetch("headerScrollHeight"), :<=, state.fetch("headerClientHeight") + 1
    assert state.fetch("headerChildrenContained"), "Expected mobile header actions to stay inside the shell"
    assert_topbar_containment(state) if state.fetch("topbarDisplay") == "flex"
  end

  def assert_topbar_containment(state)
    assert_operator state.fetch("topbarScrollHeight"), :<=, state.fetch("topbarClientHeight") + 1
    assert state.fetch("topbarChildrenContained"), "Expected header actions to stay inside the topbar"
  end

  def assert_document_fits_viewport
    dimensions = evaluate_script(<<~JAVASCRIPT)
      ({
        documentWidth: document.documentElement.scrollWidth,
        viewportWidth: document.documentElement.clientWidth,
      })
    JAVASCRIPT

    assert_operator dimensions.fetch("documentWidth"), :<=, dimensions.fetch("viewportWidth")
  end
end
