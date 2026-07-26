require "application_system_test_case"

class AppShellTest < ApplicationSystemTestCase
  test "desktop variants place and scroll one navigation tree without drawer semantics" do
    path = visit_shell_page

    assert_shell_tree("#gallery-app-shell-sidebar")
    assert_shell_tree("#gallery-app-shell-topbar")
    assert_shell_tree("#gallery-app-shell-hybrid")

    sidebar = computed_shell("gallery-app-shell-sidebar")
    assert_equal "sticky", sidebar.fetch("drawerPosition")
    assert_equal "hidden", sidebar.fetch("drawerOverflow")
    assert_equal "column", sidebar.fetch("navigationDirection")
    assert_equal "auto", sidebar.fetch("bodyOverflowY")

    topbar = computed_shell("gallery-app-shell-topbar")
    assert_equal "contents", topbar.fetch("drawerDisplay")
    assert_equal "row", topbar.fetch("navigationDirection")
    assert_equal "auto", topbar.fetch("bodyOverflowX")

    hybrid = computed_shell("gallery-app-shell-hybrid")
    assert_equal "sticky", hybrid.fetch("drawerPosition")
    assert_equal "flex", hybrid.fetch("topbarDisplay")
    assert_equal "column", hybrid.fetch("navigationDirection")

    minimal = computed_shell("gallery-app-shell-minimal")
    assert_equal "1", minimal.fetch("drawerGridRowStart")
    assert_in_delta 0, minimal.fetch("drawerOffset"), 1
    assert_equal "2", sidebar.fetch("drawerGridRowStart")
    assert_operator sidebar.fetch("drawerOffset"), :>, 0

    [ "gallery-app-shell-sidebar", "gallery-app-shell-topbar", "gallery-app-shell-hybrid" ].each do |id|
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
    visit gallery_block_path("app-shell")
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
        document.querySelector(arguments[0]).getAnimations().every(
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
