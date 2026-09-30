require "application_system_test_case"

class AppShellTest < ApplicationSystemTestCase
  test "inset examples share a continuous canvas and retain the mobile drawer in both themes" do
    examples = [
      [ "component", "app-shell", "app-shell-inset", false ],
      [ "component", "app-shell", "app-shell-inset-collapsible", true ],
      [ "composition", "application-sidebar", "sidebar-application-inset", false ],
      [ "composition", "application-sidebar", "sidebar-application-inset-collapsible", true ]
    ]
    examples.each do |kind, slug, example, collapsible|
      %w[light dark].each do |theme|
        [ 1280, 390 ].each do |width|
          resize_viewport(width:, height: 900)
          browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 900, deviceScaleFactor: 1, mobile: false) if chrome?
          visit gallery_preview_path(kind:, slug:, example:, theme:)
          assert_selector "[data-ui='inset-workspace'][data-enhanced]"
          if collapsible
            assert_selector "[data-slot='app-shell-sidebar-toggle']", visible: :all
          else
            assert_no_selector "[data-slot='app-shell-sidebar-toggle']", visible: :all
          end
          geometry = evaluate_script(<<~JS)
            (() => {
              const shell = document.querySelector('[data-ui="inset-workspace"]')
              const s = shell.getBoundingClientRect()
              const main = shell.querySelector('[data-slot="app-shell-main"]')
              const m = main.getBoundingClientRect()
              const topbar = shell.querySelector('[data-slot="app-shell-topbar"]')
              const t = topbar.getBoundingClientRect()
              const r = shell.querySelector('[data-slot="app-shell-sidebar"]').getBoundingClientRect()
              const gutter = getComputedStyle(shell.querySelector('[data-ui="workspace-content"]'))
              return { height: s.height, left: m.left, right: m.right,
                gaps: [t.top-s.top, s.right-m.right, s.bottom-m.bottom, m.left-r.right],
                seam: m.top-t.bottom, gutter: parseFloat(gutter.paddingLeft),
                radius: parseFloat(getComputedStyle(main).borderBottomLeftRadius),
                overflow: document.documentElement.scrollWidth-innerWidth }
            })()
          JS
          assert_in_delta 900, geometry.fetch("height"), 1
          assert_operator geometry.fetch("overflow"), :<=, 0
          if width == 1280
            geometry.fetch("gaps").zip([ 12, 12, 12, 0 ]).each { |actual, expected| assert_in_delta expected, actual, 1 }
            assert_in_delta 0, geometry.fetch("seam"), 1
            assert_in_delta 24, geometry.fetch("gutter"), 1
            assert_operator geometry.fetch("radius"), :>, 0
            if collapsible
              pin = find("[data-slot='app-shell-sidebar-toggle']")
              sidebar = find("[data-slot='app-shell-sidebar']")
              main = find("[data-slot='app-shell-main']")
              pin.click
              assert_selector "[data-slot='app-shell-sidebar-toggle'][aria-pressed='false']"
              wait_until { evaluate_script("arguments[0].getBoundingClientRect().width < 100", sidebar) }
              wait_for_animations("[data-ui='inset-workspace']")
              collapsed_left = evaluate_script("arguments[0].getBoundingClientRect().left", main)
              assert_operator collapsed_left, :<, geometry.fetch("left")
              main.hover
              sidebar.hover
              wait_until { evaluate_script("arguments[0].getBoundingClientRect().width > 100", sidebar) }
              assert_in_delta collapsed_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
              assert_equal evaluate_script("getComputedStyle(arguments[0].closest('[data-nk=app-shell]')).backgroundColor", sidebar),
                evaluate_script("getComputedStyle(arguments[0]).backgroundColor", sidebar)
              pin.click
              assert_selector "[data-slot='app-shell-sidebar-toggle'][aria-pressed='true']"
              wait_for_animations("[data-ui='inset-workspace']")
              assert_in_delta geometry.fetch("left"), evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
              pin.click
              wait_until { evaluate_script("arguments[0].getBoundingClientRect().width < 100", sidebar) }
              wait_for_animations("[data-ui='inset-workspace']")
              execute_script("arguments[0].focus()", first("[data-slot='app-navigation-item-link']"))
              wait_until { evaluate_script("arguments[0].getBoundingClientRect().width > 100", sidebar) }
              assert_in_delta collapsed_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
            end
          else
            assert_no_selector "[data-slot='app-shell-sidebar-toggle']"
            assert_in_delta 0, geometry.fetch("left"), 1
            assert_in_delta width, geometry.fetch("right"), 1
            assert_in_delta 16, geometry.fetch("gutter"), 1
            assert_in_delta 0, geometry.fetch("radius"), 1
            find("[data-slot='app-shell-mobile-trigger']").click
            assert_selector "[data-slot='app-shell-dialog'][open] [data-nk='app-navigation']", count: 1
            wait_for_animations("[data-slot='app-shell-dialog'][open]")
            find("[data-slot='app-shell-mobile-close']").click
            assert_no_selector "[data-slot='app-shell-dialog'][open]"
          end
        end
      end
    end
  end

  test "sidebar operations demonstrates static pinned and rail configurations" do
    resize_viewport(width: 1200, height: 900)
    visit gallery_composition_path(slug: "application-sidebar")
    static = "#gallery-sidebar-application-populated"
    pinned = "#gallery-sidebar-application-empty"
    rail = "#gallery-sidebar-application-error"
    assert_selector "#{static}[data-enhanced][data-nk--app-shell-collapsible-value='false']"
    assert_no_selector "#{static} [data-slot='app-shell-sidebar-toggle']", visible: :all
    assert_selector "#{pinned}[data-enhanced][data-nk--app-shell-pinned-value='true']"
    assert_selector "#{pinned} [data-slot='app-shell-sidebar-toggle'][aria-pressed='true']"
    assert_selector "#{rail}[data-enhanced][data-nk--app-shell-pinned-value='false']"
    sidebar = find("#{rail} > [data-slot='app-shell-sidebar']")
    main = find("#{rail} > [data-slot='app-shell-main']")
    wait_until { evaluate_script("arguments[0].getBoundingClientRect().width < 100", sidebar) }
    wait_for_animations(rail)
    main_left = evaluate_script("arguments[0].getBoundingClientRect().left", main)
    execute_script("arguments[0].focus()", first("#{rail} [data-slot='app-navigation-item-link']"))
    wait_until { evaluate_script("arguments[0].getBoundingClientRect().width > 100", sidebar) }
    assert_in_delta main_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
  end

  test "default sidebar stays static with no pin or peek behavior" do
    visit_shell_page
    root = "#gallery-app-shell-static"
    assert_selector "#{root}[data-nk--app-shell-collapsible-value='false']"
    assert_no_selector "#{root} [data-slot='app-shell-sidebar-toggle']", visible: :all
    sidebar = find("#{root} > [data-slot='app-shell-sidebar']")
    width = evaluate_script("arguments[0].getBoundingClientRect().width", sidebar)
    execute_script(<<~JAVASCRIPT, root)
      const controller = window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector(arguments[0]), "nk--app-shell"
      );
      controller.togglePin({ detail: 1 });
    JAVASCRIPT
    assert_selector "#{root}[data-nk--app-shell-pinned-value='true']"
    page.driver.browser.action.move_to(sidebar.native).perform
    assert_in_delta width, evaluate_script("arguments[0].getBoundingClientRect().width", sidebar), 1
    assert_equal "0s", evaluate_script("getComputedStyle(arguments[0]).transitionDuration", sidebar)
  end

  test "rail peeks on hover and keyboard focus without shifting content and pins on click" do
    visit_shell_page
    root = "#gallery-app-shell-sidebar"
    pin = find("#{root} [data-slot='app-shell-sidebar-toggle']")
    main = find("#{root} > [data-slot='app-shell-main']")
    sidebar = find("#{root} > [data-slot='app-shell-sidebar']")
    icon = first("#{root} [data-slot='app-navigation-item-icon']")
    expanded_left = evaluate_script("arguments[0].getBoundingClientRect().left", main)
    icon_top = evaluate_script("arguments[0].getBoundingClientRect().top - arguments[1].getBoundingClientRect().top", icon, sidebar)

    pin.click
    assert_selector "#{root}[data-nk--app-shell-pinned-value='false']"
    assert_equal "false", pin["aria-pressed"]
    assert_selector "#{root}[data-nk--app-shell-hover-suppressed-value='true']"
    wait_until do
      evaluate_script("arguments[0].getBoundingClientRect().width < 100", sidebar)
    end
    wait_for_animations(root)
    assert evaluate_script("arguments[0].matches(':hover')", sidebar), "Pointer should still be on the collapsed rail"
    page.driver.browser.action.move_to(main.native).perform
    assert_selector "#{root}[data-nk--app-shell-hover-suppressed-value='false']"
    rail_left = evaluate_script("arguments[0].getBoundingClientRect().left", main)
    assert_operator rail_left, :<, expanded_left
    assert_in_delta icon_top, evaluate_script("arguments[0].getBoundingClientRect().top - arguments[1].getBoundingClientRect().top", icon, sidebar), 1
    assert_in_delta evaluate_script("arguments[0].getBoundingClientRect().left + arguments[0].getBoundingClientRect().width / 2", icon),
      evaluate_script("arguments[0].getBoundingClientRect().left + arguments[0].getBoundingClientRect().width / 2", pin), 0.5
    link = first("#{root} [data-slot='app-navigation-item-link']")
    left_inset, right_inset = evaluate_script(<<~JAVASCRIPT, link, sidebar)
      (() => {
        const link = arguments[0].getBoundingClientRect();
        const sidebar = arguments[1].getBoundingClientRect();
        return [link.left - sidebar.left, sidebar.right - link.right];
      })()
    JAVASCRIPT
    assert_in_delta left_inset, right_inset, 1
    brand = find("#{root} [data-slot='app-shell-brand-content']", visible: :all)
    assert_equal "inset(50%)", evaluate_script("getComputedStyle(arguments[0]).clipPath", brand)
    mark = find("#{root} [data-slot='app-shell-brand-icon']")
    assert_in_delta evaluate_script("arguments[0].getBoundingClientRect().left", icon),
      evaluate_script("arguments[0].getBoundingClientRect().left", mark), 1

    page.driver.browser.action.move_to(link.native).perform
    wait_until do
      evaluate_script("arguments[0].getBoundingClientRect().width > 100", sidebar)
    end
    assert_in_delta rail_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
    assert_in_delta icon_top, evaluate_script("arguments[0].getBoundingClientRect().top - arguments[1].getBoundingClientRect().top", icon, sidebar), 1
    assert_equal "none", evaluate_script("getComputedStyle(arguments[0]).clipPath", brand)
    page.driver.browser.action.move_to(main.native).perform
    wait_until do
      evaluate_script("arguments[0].getBoundingClientRect().width < 100", sidebar)
    end

    execute_script("arguments[0].focus()", link)
    wait_until do
      evaluate_script("arguments[0].getBoundingClientRect().width > 100", sidebar)
    end
    assert_in_delta rail_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
    pin.send_keys(:space)
    assert_selector "#{root}[data-nk--app-shell-pinned-value='true']"
    assert_equal "true", pin["aria-pressed"]
    wait_for_animations(root)
    assert_in_delta expanded_left, evaluate_script("arguments[0].getBoundingClientRect().left", main), 1
  end

  test "collapsing an outer shell does not hide nested shell labels" do
    visit_shell_page
    outer = "#gallery-shell"
    nested = "#gallery-app-shell-sidebar"
    find("#{outer} > [data-slot='app-shell-sidebar'] > [data-slot='app-shell-sidebar-toggle']").click
    page.driver.browser.action.move_to(find("#{nested} > [data-slot='app-shell-main']").native).perform
    label = first("#{nested} [data-slot='app-navigation-item-label']")
    assert_equal "none", evaluate_script("getComputedStyle(arguments[0]).clipPath", label)
    assert_selector "#{nested}[data-nk--app-shell-pinned-value='true']"
    assert_selector "#{outer}[data-nk--app-shell-pinned-value='false']"
  end

  test "desktop variants place and scroll one navigation tree without drawer semantics" do
    path = visit_shell_page

    assert_shell_tree("#gallery-app-shell-sidebar")
    assert_shell_tree("#gallery-app-shell-topbar")

    sidebar = computed_shell("gallery-app-shell-sidebar")
    assert_equal "sticky", sidebar.fetch("drawerPosition")
    assert_equal "hidden", sidebar.fetch("drawerOverflow")
    assert_equal "column", sidebar.fetch("navigationDirection")
    assert_equal "auto", sidebar.fetch("bodyOverflowY")

    topbar = computed_shell("gallery-app-shell-topbar")
    assert_equal "contents", topbar.fetch("drawerDisplay")
    assert_equal "row", topbar.fetch("navigationDirection")
    assert_equal "auto", topbar.fetch("bodyOverflowX")

    minimal = computed_shell("gallery-app-shell-minimal")
    assert_equal "1", minimal.fetch("drawerGridRowStart")
    assert_in_delta 0, minimal.fetch("drawerOffset"), 1
    assert_equal "2", sidebar.fetch("drawerGridRowStart")
    assert_operator sidebar.fetch("drawerOffset"), :>, 0

    [ "gallery-app-shell-sidebar", "gallery-app-shell-topbar" ].each do |id|
      sidebar = find("##{id} [data-slot='app-shell-sidebar']", visible: :all)
      dialog = find("##{id} [data-slot='app-shell-dialog']", visible: :all)
      assert_equal "div", sidebar.tag_name
      assert_equal false, evaluate_script("arguments[0].open", dialog)
      assert_equal false, evaluate_script("arguments[0].matches(':modal')", dialog)
      assert_selector "##{id} > [data-slot='app-shell-sidebar'] > [data-slot='app-shell-navigation']", count: 1
    end
    assert_no_severe_console_errors(context: path)
  end

  test "narrow disclosure moves focus traps closes and clears state on desktop resize" do
    path = visit_shell_page
    root = "#gallery-app-shell-sidebar"
    sidebar = "#{root} [data-slot='app-shell-sidebar']"
    dialog = "#{root} [data-slot='app-shell-dialog']"
    trigger = "#{root} [data-slot='app-shell-mobile-trigger']"
    close = "#{root} [data-slot='app-shell-mobile-close']"

    first_item = first("#{root} [data-slot='app-navigation-item-link']")
    execute_script("arguments[0].focus()", first_item)
    assert_equal first_item.native, active_element

    resize_viewport(width: 700, height: 900)
    assert_selector "#{root}[data-enhanced][data-state='closed']"
    assert_equal "none", evaluate_script(
      "getComputedStyle(document.querySelector(arguments[0])).display",
      sidebar
    )
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_focused trigger

    find(trigger).click

    assert_selector "#{root}[data-state='open']"
    assert_selector "#{trigger}[aria-expanded='true'][aria-label='Close navigation']"
    assert_selector "#{dialog}[open][aria-label='Workspace navigation']"
    assert_equal true, evaluate_script(
      "document.querySelector(arguments[0]).matches(':modal')",
      dialog
    )
    assert_selector "#{dialog} > [data-slot='app-shell-navigation']", count: 1
    assert_no_selector "#{sidebar} > [data-slot='app-shell-navigation']", visible: :all
    assert_focused close

    main = find("#{root} > [data-slot='app-shell-main']", visible: :all)
    execute_script("arguments[0].focus()", main)
    assert_focused close

    find(close).send_keys([ :shift, :tab ])
    assert_includes %w[body dialog], evaluate_script(<<~JAVASCRIPT, dialog)
      document.querySelector(arguments[0]).contains(document.activeElement)
        ? "dialog"
        : document.activeElement.tagName.toLowerCase()
    JAVASCRIPT
    active_element.send_keys(:tab)
    assert_equal true, evaluate_script(
      "document.querySelector(arguments[0]).contains(document.activeElement)",
      dialog
    )

    active_element.send_keys(:escape)
    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{trigger}[aria-expanded='false'][aria-label='Open navigation']"
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']", visible: :all
    assert_focused trigger

    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    wait_for_animations(dialog)
    find(close).click
    assert_selector "#{root}[data-state='closed']"
    assert_focused trigger

    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    execute_script(<<~JAVASCRIPT, dialog)
      const dialog = document.querySelector(arguments[0]);
      const bounds = dialog.getBoundingClientRect();
      dialog.dispatchEvent(new MouseEvent("click", {
        bubbles: true,
        clientX: bounds.right + 20,
        clientY: bounds.top + 20
      }));
    JAVASCRIPT
    assert_selector "#{root}[data-state='closed']"
    assert_focused trigger

    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    execute_script(<<~JAVASCRIPT)
      document.dispatchEvent(
        new CustomEvent("turbo:before-visit", { bubbles: true })
      );
    JAVASCRIPT
    assert_selector "#{root}[data-state='closed']"

    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    resize_viewport(width: 1200, height: 900)

    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{trigger}[aria-expanded='false']", visible: :all
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']"
    assert_no_severe_console_errors(context: path)
  end

  test "morph replacement keeps live dialog navigation and trigger targets" do
    path = visit_shell_page
    resize_viewport(width: 700, height: 900)
    root = "#gallery-app-shell-sidebar"
    dialog = "#{root} [data-slot='app-shell-dialog']"
    trigger = "#{root} [data-slot='app-shell-mobile-trigger']"

    find(trigger).click
    assert_selector "#{dialog}[open] > [data-slot='app-shell-navigation']"

    execute_script(<<~JAVASCRIPT, dialog)
      const current = document.querySelector(arguments[0]);
      const replacement = current.cloneNode(true);
      replacement.removeAttribute("open");
      current.replaceWith(replacement);
    JAVASCRIPT

    assert_selector "#{dialog}[open] > [data-slot='app-shell-navigation']"
    assert_equal true, evaluate_script(
      "document.querySelector(arguments[0]).matches(':modal')",
      dialog
    )
    active_element.send_keys(:escape)
    assert_selector "#{dialog}:not([open])", visible: :all

    execute_script(<<~JAVASCRIPT, trigger)
      const current = document.querySelector(arguments[0]);
      current.replaceWith(current.cloneNode(true));
    JAVASCRIPT

    find(trigger).click
    assert_selector "#{dialog}[open]"
    assert_selector "#{trigger}[aria-expanded='true'][aria-label='Close navigation']"
    assert_no_severe_console_errors(context: path)
  end

  test "a Turbo refresh morph preserves pin state until a full page load" do
    visit_shell_page
    unpinned = "#gallery-app-shell-sidebar"
    pinned = "#gallery-app-shell-rail"
    find("#{unpinned} [data-slot='app-shell-sidebar-toggle']").click
    find("#{pinned} [data-slot='app-shell-sidebar-toggle']").click
    assert_selector "#{unpinned}[data-nk--app-shell-pinned-value='false']"
    assert_selector "#{pinned}[data-nk--app-shell-pinned-value='true']"
    execute_script(<<~JS, unpinned, pinned)
      window.sidebarControllers = Array.from(arguments).map(selector =>
        window.Stimulus.getControllerForElementAndIdentifier(document.querySelector(selector), 'nk--app-shell'))
    JS

    install_morph_counter
    refresh_with_turbo_stream
    wait_until { evaluate_script("window.__nitroMorphCount") == 1 }

    [ [ unpinned, false ], [ pinned, true ] ].each_with_index do |(root, state), index|
      assert_selector "#{root}[data-enhanced][data-nk--app-shell-pinned-value='#{state}']"
      assert_selector "#{root} [data-slot='app-shell-sidebar-toggle'][aria-pressed='#{state}']"
      assert evaluate_script(<<~JS, root, index), "Expected the same shell controller after morph"
        window.Stimulus.getControllerForElementAndIdentifier(document.querySelector(arguments[0]), 'nk--app-shell')
          === window.sidebarControllers[arguments[1]]
      JS
    end

    browser.navigate.refresh
    assert_selector "#{unpinned}[data-enhanced][data-nk--app-shell-pinned-value='true']"
    assert_selector "#{pinned}[data-enhanced][data-nk--app-shell-pinned-value='false']"
  end

  test "a Turbo refresh morph keeps exactly one live navigation tree in the open drawer" do
    path = visit_shell_page
    resize_viewport(width: 700, height: 900)
    root = "#gallery-app-shell-sidebar"
    sidebar = "#{root} [data-slot='app-shell-sidebar']"
    dialog = "#{root} [data-slot='app-shell-dialog']"
    trigger = "#{root} [data-slot='app-shell-mobile-trigger']"

    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    assert_selector "#{dialog}[open] > [data-slot='app-shell-navigation']"

    install_morph_counter
    refresh_with_turbo_stream
    wait_until(message: "Turbo did not morph the page") do
      evaluate_script("window.__nitroMorphCount") == 1
    end

    # The morph reinstates the server-rendered closed shell. The single live
    # navigation tree must survive that reconciliation exactly once, back in
    # the sidebar, without drawer semantics or a duplicated tree.
    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{root}[data-enhanced]"
    assert_selector "#{root} [data-nk='app-navigation']", count: 1, visible: :all
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']", count: 1, visible: :all
    assert_no_selector "#{dialog} [data-slot='app-shell-navigation']", visible: :all
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#{trigger}[aria-expanded='false']"
    assert_no_selector "#{sidebar} > [data-slot='app-shell-navigation'][inert]", visible: :all
    assert_no_selector "#{sidebar} > [data-slot='app-shell-navigation'][aria-hidden]", visible: :all
    assert_shell_controller_connected(root)

    # The reconciled shell still opens, moves, and closes the same tree.
    find(trigger).click
    assert_selector "#{root}[data-state='open']"
    assert_selector "#{dialog}[open] > [data-slot='app-shell-navigation']", count: 1
    assert_selector "#{root} [data-nk='app-navigation']", count: 1, visible: :all
    active_element.send_keys(:escape)
    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']", count: 1, visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "disconnect restores the visible no JavaScript narrow navigation" do
    path = visit_shell_page
    resize_viewport(width: 700, height: 900)
    root = "#gallery-app-shell-minimal"
    sidebar = "#{root} [data-slot='app-shell-sidebar']"
    dialog = "#{root} [data-slot='app-shell-dialog']"
    trigger = "#{root} [data-slot='app-shell-mobile-trigger']"

    assert_selector "#{root}[data-enhanced]"
    find(trigger).click
    assert_selector "#{dialog}[open] > [data-slot='app-shell-navigation']"

    execute_script(<<~JAVASCRIPT)
      document.querySelector("#{root}").removeAttribute("data-controller");
    JAVASCRIPT

    assert_selector "#{root}:not([data-enhanced])"
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']"
    state = computed_shell("gallery-app-shell-minimal")
    assert_equal "static", state.fetch("drawerPosition")
    assert_equal "visible", state.fetch("drawerVisibility")
    assert_equal "none", state.fetch("drawerTransform")
    assert_equal "none", evaluate_script(
      "getComputedStyle(document.querySelector(arguments[0])).display",
      trigger
    )
    assert_no_severe_console_errors(context: path)
  end

  private

  def visit_shell_page
    resize_viewport(width: 1200, height: 900)
    visit gallery_component_path("app-shell")
    assert_selector "#gallery-app-shell-sidebar[data-enhanced]"
    page.current_path
  end

  def assert_shell_tree(root)
    assert_selector "#{root} [data-nk='app-navigation']", count: 1
    assert_selector "#{root} > [data-slot='app-shell-sidebar'] > [data-slot='app-shell-navigation']", count: 1
  end

  def install_morph_counter
    execute_script <<~JAVASCRIPT
      window.__nitroMorphCount = 0;
      document.addEventListener("turbo:morph", () => window.__nitroMorphCount += 1, { once: true });
    JAVASCRIPT
  end

  def refresh_with_turbo_stream
    execute_script <<~JAVASCRIPT
      Turbo.renderStreamMessage('<turbo-stream action="refresh"></turbo-stream>');
    JAVASCRIPT
  end

  def assert_shell_controller_connected(selector)
    connected = evaluate_script(<<~JAVASCRIPT, selector)
      window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector(arguments[0]),
        "nk--app-shell"
      ) !== null
    JAVASCRIPT
    assert connected, "Expected nk--app-shell to stay connected at #{selector}"
  end

  def wait_for_animations(selector)
    wait_until(message: "#{selector} animations did not settle") do
      evaluate_script(<<~JAVASCRIPT, selector)
        document.querySelector(arguments[0]).getAnimations({subtree: true}).every(
          (animation) => animation.playState === "finished"
        )
      JAVASCRIPT
    end
  end

  def computed_shell(id)
    evaluate_script(<<~JAVASCRIPT, id)
      (() => {
        const root = document.getElementById(arguments[0]);
        const drawer = root.querySelector('[data-slot="app-shell-sidebar"]');
        const navigation = root.querySelector('[data-nk="app-navigation"]');
        const body = navigation.querySelector('[data-slot="app-navigation-body"]');
        const topbar = root.querySelector('[data-slot="app-shell-topbar"]');
        const drawerStyle = getComputedStyle(drawer);
        const bodyStyle = getComputedStyle(body);

        return {
          drawerDisplay: drawerStyle.display,
          drawerPosition: drawerStyle.position,
          drawerOverflow: drawerStyle.overflow,
          drawerTransform: drawerStyle.transform,
          drawerVisibility: drawerStyle.visibility,
          drawerGridRowStart: drawerStyle.gridRowStart,
          drawerOffset:
            drawer.getBoundingClientRect().top - root.getBoundingClientRect().top,
          navigationDirection: getComputedStyle(navigation).flexDirection,
          bodyOverflowX: bodyStyle.overflowX,
          bodyOverflowY: bodyStyle.overflowY,
          topbarDisplay: topbar ? getComputedStyle(topbar).display : null,
        };
      })()
    JAVASCRIPT
  end
end
