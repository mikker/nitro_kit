require "application_system_test_case"

# Temporary: captures CI Chrome input and animation behaviour for the sidebar rail.
class CiDiagnosticsTest < ApplicationSystemTestCase
  test "rail diagnostics" do
    skip "Chrome only" unless chrome?
    resize_viewport(width: 1200, height: 900)
    visit gallery_component_path("app-shell")
    assert_selector "#gallery-app-shell-sidebar[data-enhanced]"
    root = "#gallery-app-shell-sidebar"

    report "environment", evaluate_script(<<~JS)
      ({
        ua: navigator.userAgent,
        hover: matchMedia('(hover: hover)').matches,
        anyHover: matchMedia('(any-hover: hover)').matches,
        pointerFine: matchMedia('(pointer: fine)').matches,
        anyPointerFine: matchMedia('(any-pointer: fine)').matches,
        pointerNone: matchMedia('(pointer: none)').matches,
        reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches,
        narrow: matchMedia('(width < 48rem)').matches,
        inner: [innerWidth, innerHeight], outer: [outerWidth, outerHeight],
        screen: [screen.width, screen.height], dpr: devicePixelRatio,
        hasFocus: document.hasFocus(), visibility: document.visibilityState,
        maxTouchPoints: navigator.maxTouchPoints
      })
    JS
    report "capabilities", browser.capabilities.as_json.slice("browserVersion", "chrome", "platformName").to_s[0, 600]

    execute_script(<<~JS, root)
      const root = document.querySelector(arguments[0]);
      const sidebar = root.querySelector(':scope > [data-slot="app-shell-sidebar"]');
      const pin = root.querySelector('[data-slot="app-shell-sidebar-toggle"]');
      const brand = root.querySelector('[data-slot="app-shell-brand"]');
      const t0 = performance.now();
      window.__log = [];
      const slot = (el) => el && el.getAttribute ? (el.getAttribute('data-slot') || el.tagName.toLowerCase()) : String(el);
      const log = (entry) => window.__log.push({ t: Math.round(performance.now() - t0), ...entry });
      window.__pointer = null;
      ['pointerenter','pointerleave','pointerover','pointerout','mouseenter','mouseleave'].forEach(type => {
        sidebar.addEventListener(type, e => log({ type, on: 'sidebar', target: slot(e.target), related: slot(e.relatedTarget), x: e.clientX, y: e.clientY, pointerType: e.pointerType }));
        brand && brand.addEventListener(type, e => log({ type, on: 'brand', target: slot(e.target), related: slot(e.relatedTarget), x: e.clientX, y: e.clientY }));
      });
      document.addEventListener('pointermove', e => { window.__pointer = [e.clientX, e.clientY]; }, true);
      document.addEventListener('mousemove', e => { window.__pointer = [e.clientX, e.clientY]; }, true);
      pin.addEventListener('click', e => log({ type: 'click', detail: e.detail, trusted: e.isTrusted, pointerType: e.pointerType, button: e.button, x: e.clientX, y: e.clientY, ctor: e.constructor.name }), true);
      pin.addEventListener('pointerdown', e => log({ type: 'pointerdown', pointerType: e.pointerType, x: e.clientX, y: e.clientY }), true);
      new MutationObserver(records => records.forEach(r => log({ type: 'attr', name: r.attributeName, value: root.getAttribute(r.attributeName) })))
        .observe(root, { attributes: true, attributeFilter: ['data-nk--app-shell-pinned-value', 'data-nk--app-shell-hover-suppressed-value'] });
      window.__rects = () => ({
        pin: pin.getBoundingClientRect().toJSON(), sidebar: sidebar.getBoundingClientRect().toJSON(),
        pinHover: pin.matches(':hover'), sidebarHover: sidebar.matches(':hover'),
        navHover: root.querySelector('[data-slot="app-shell-navigation"]').matches(':hover'),
        pointer: window.__pointer,
        under: window.__pointer ? slot(document.elementFromPoint(...window.__pointer)) : null,
        suppressed: root.getAttribute('data-nk--app-shell-hover-suppressed-value'),
        pinned: root.getAttribute('data-nk--app-shell-pinned-value'),
        panelWidth: getComputedStyle(sidebar).inlineSize,
        scrollY: scrollY
      });
    JS

    pin = find("#{root} [data-slot='app-shell-sidebar-toggle']")
    main = find("#{root} > [data-slot='app-shell-main']")
    sidebar = find("#{root} > [data-slot='app-shell-sidebar']")
    report "before click", evaluate_script("window.__rects()")
    pin.click
    sleep 0.6
    report "after click rects", evaluate_script("window.__rects()")
    report "after click log", evaluate_script("window.__log.splice(0)")

    page.driver.browser.action.move_to(main.native).perform
    sleep 0.3
    report "after move to main", evaluate_script("window.__rects()")
    report "move to main log", evaluate_script("window.__log.splice(0)")

    sidebar.hover
    sleep 0.6
    report "after sidebar.hover", evaluate_script("window.__rects()")
    report "sidebar.hover log", evaluate_script("window.__log.splice(0)")

    nav = find("#{root} [data-slot='app-shell-navigation']")
    page.driver.browser.action.move_to(nav.native).perform
    sleep 0.6
    report "after move_to nav", evaluate_script("window.__rects()")
    report "move_to nav log", evaluate_script("window.__log.splice(0)")

    rect = evaluate_script("document.querySelector(arguments[0]).getBoundingClientRect().toJSON()", "#{root} [data-slot='app-shell-navigation']")
    x = (rect["left"] + rect["width"] / 2).round
    y = (rect["top"] + rect["height"] / 2).round
    browser.execute_cdp("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
    sleep 0.6
    report "after raw CDP mouseMoved to #{x},#{y}", evaluate_script("window.__rects()")
    report "raw CDP log", evaluate_script("window.__log.splice(0)")

    # Animation synchronisation
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "no-preference" } ])
    visit gallery_preview_path(kind: "component", slug: "app-shell", example: "app-shell-sidebar")
    assert_selector "[data-nk='app-shell'][data-enhanced]"
    execute_script(<<~JS)
      const shell = document.querySelector('[data-nk="app-shell"]')
      const sidebar = shell.querySelector('[data-slot="app-shell-sidebar"]')
      const main = shell.querySelector('[data-slot="app-shell-main"]')
      const item = shell.querySelector('[data-slot="app-navigation-item-link"]')
      window.__frames = []; window.__framesDone = false
      const t0 = performance.now()
      function anim(el) { return el.getAnimations().map(a => ({ prop: a.transitionProperty, state: a.playState, start: a.startTime && Math.round(a.startTime - t0), cur: a.currentTime && Math.round(a.currentTime) })) }
      function sample(ts) {
        const origin = shell.getBoundingClientRect().left
        const w = sidebar.getBoundingClientRect().width
        window.__frames.push({ t: Math.round(performance.now() - t0), raf: Math.round(ts - t0), width: w, main: main.getBoundingClientRect().left - origin, item: item.getBoundingClientRect().width,
          sidebarAnim: anim(sidebar), itemAnim: anim(item), shellAnim: anim(shell) })
        if ((window.__frames.length > 3 && Math.abs(w - 64) < 0.1) || window.__frames.length >= 60) window.__framesDone = true
        else requestAnimationFrame(sample)
      }
      requestAnimationFrame(sample)
    JS
    find("[data-slot='app-shell-sidebar-toggle']").click
    wait_until { evaluate_script("window.__framesDone") }
    frames = evaluate_script("window.__frames")
    report "frame count", frames.length
    frames.first(14).each { |frame| report "frame", frame }
  ensure
    browser.execute_cdp("Emulation.setEmulatedMedia", features: []) if chrome?
  end

  private

  def report(label, value)
    puts "DIAG #{label}: #{value.is_a?(String) ? value : value.to_json}"
  end
end
