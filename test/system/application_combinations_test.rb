require "application_system_test_case"

class ApplicationCombinationsTest < ApplicationSystemTestCase
  STORAGE_KEY = NitroKit::AppearanceBootstrap::STORAGE_KEY
  APPLICATIONS = {
    "application-sidebar" => {
      layout: "sidebar",
      states: %w[populated empty error],
      source: "sidebar_application_page.rb"
    },
    "application-topbar" => {
      layout: "topbar",
      states: %w[populated loading long],
      source: "topbar_application_page.rb"
    },
    "application-hybrid" => {
      layout: "hybrid",
      states: %w[populated missing error],
      source: "hybrid_application_page.rb"
    }
  }.freeze

  teardown do
    execute_script("try { localStorage.removeItem(arguments[0]) } catch (_error) {}", STORAGE_KEY)
  end

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

      assert_selector "#{root}[data-enhanced][data-variant='#{layout}']"
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
      assert_gallery_navigation_bounded
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

  test "every complete application exposes the exact executable AppShell source" do
    APPLICATIONS.each do |slug, contract|
      path = gallery_composition_path(slug:)
      visit path

      layout = contract.fetch(:layout)
      contract.fetch(:states).each do |state|
        example = "#example-#{layout}-application-#{state}"
        code_tab = "#{example}-presentation-code-tab"
        code_panel = "#{example}-presentation-code-panel"

        assert_selector "#{code_panel}[hidden][aria-hidden='true']", visible: :all
        find(code_tab).click

        assert_selector "#{code_tab}[aria-selected='true'][data-state='active']"
        assert_selector "#{code_panel}:not([hidden])[aria-hidden='false']"
        assert_selector "#{example} [data-gallery='code-path']", text: /#{contract.fetch(:source)}\z/
        assert_selector "#{example} [data-gallery='code-source']", text: /render NitroKit::AppShell\.new/
        assert_selector "#{example} [data-gallery='code-source']", text: /layout: :#{layout}/
        assert_selector "#{example} [data-gallery='code-source']", text: /gallery_application_state: "#{state}"/
      end

      assert_no_severe_console_errors(context: path)
    end
  end

  test "application examples synchronize appearance and accept a native multipart drop" do
    visit gallery_root_path
    execute_script("localStorage.removeItem(arguments[0])", STORAGE_KEY)
    hybrid_path = gallery_composition_path(slug: "application-hybrid")
    visit hybrid_path

    assert_selector "#gallery-hybrid-application-populated [data-nk='appearance-picker'][data-state='system']", count: 2
    find("#gallery-hybrid-application-navigation-appearance-dark").click
    assert_selector "html[data-theme-preference='dark'][data-theme='dark']"
    assert_selector "#gallery-hybrid-application-populated [data-nk='appearance-picker'][data-state='dark']", count: 2
    assert_no_severe_console_errors(context: hybrid_path)

    sidebar_path = gallery_composition_path(slug: "application-sidebar")
    visit sidebar_path
    attach_file("gallery-sidebar-application-dropzone-input", file_fixture("profile.txt"))

    assert_selector "#gallery-sidebar-application-dropzone[data-state='success']"
    assert_selector "#gallery-sidebar-application-dropzone [data-slot='dropzone-preview']", count: 1
    assert_selector "#gallery-sidebar-application-dropzone [data-slot='dropzone-file-name']", text: "profile.txt"
    assert_no_severe_console_errors(context: sidebar_path)
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

  def assert_gallery_navigation_bounded
    geometry = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const navigation = document.querySelector('[data-gallery="navigation"]');
        const heading = document.querySelector('[data-gallery="composition-header"] h1');

        return {
          navigationHeight: navigation.clientHeight,
          navigationScrollHeight: navigation.scrollHeight,
          headingTop: heading.getBoundingClientRect().top,
          viewportHeight: window.innerHeight,
        };
      })()
    JAVASCRIPT

    assert_operator geometry.fetch("navigationHeight"), :<=, geometry.fetch("viewportHeight") * 0.5
    assert_operator geometry.fetch("navigationScrollHeight"), :>, geometry.fetch("navigationHeight")
    assert_operator geometry.fetch("headingTop"), :<, geometry.fetch("viewportHeight")
  end
end
