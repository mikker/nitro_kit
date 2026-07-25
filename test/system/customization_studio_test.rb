require "application_system_test_case"

class CustomizationStudioTest < ApplicationSystemTestCase
  STORAGE_KEY = NitroKit::AppearanceBootstrap::STORAGE_KEY

  teardown do
    execute_script("try { localStorage.removeItem(arguments[0]) } catch (_error) {}", STORAGE_KEY)
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "", features: [])
  end

  test "closed choices update preview readable URL and deterministic exports immediately" do
    visit_fresh_studio
    original_appearance = document_appearance
    assert_equal "System", find("#customizer-font-system", visible: :all).native.accessible_name

    choose_option(:accent, :rose)
    choose_option(:neutral, :stone)
    choose_option(:radius, :lg)
    choose_option(:density, :compact)
    choose_option(:font, :serif)
    choose_option(:shell, :hybrid)

    preset = Gallery::ThemePreset.new(
      accent: :rose,
      neutral: :stone,
      radius: :lg,
      density: :compact,
      font: :serif,
      shell: :hybrid
    )

    assert_equal preset.query_string, URI.parse(page.current_url).query
    assert_selector "[data-gallery='theme-preview'] [data-gallery-customizer-shell][data-variant='hybrid']"
    assert_equal preset.css, target_text("cssOutput")
    assert_equal preset.app_shell_ruby, target_text("rubyOutput")
    assert_includes target_text("previewStyle"), "--nk-radius-xl: 1rem;"
    choose_option(:appearance, :light)
    assert_equal "oklch(0.56 0.253 17.585)", preview_token("--nk-color-primary")

    query = URI.parse(page.current_url).query
    choose_option(:appearance, :dark)
    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='dark'][data-theme='dark']"
    assert_equal query, URI.parse(page.current_url).query
    assert_equal original_appearance, document_appearance

    choose_option(:appearance, :light)
    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='light'][data-theme='light']"
    assert_equal original_appearance, document_appearance

    click_button "Reset"
    defaults = Gallery::ThemePreset.new
    assert_equal defaults.query_string, URI.parse(page.current_url).query
    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='system']"
    assert_selector "[data-gallery-customizer-shell][data-variant='sidebar']"
    assert_text "Version 1 defaults restored."
    assert_equal original_appearance, document_appearance
    assert_no_severe_console_errors
  end

  test "system preview stays live without touching visitor appearance or storage" do
    emulate_system_theme("dark")
    visit_fresh_studio(clear_media: false)
    original_appearance = document_appearance
    original_storage = evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY)

    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='system'][data-theme='dark']"

    emulate_system_theme("light")
    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='system'][data-theme='light']"
    assert_equal original_appearance.fetch("preference"), document_appearance.fetch("preference")
    assert_nil evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY) if original_storage.nil?
    assert_equal original_storage, evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY) unless original_storage.nil?

    choose_option(:appearance, :dark)
    emulate_system_theme("light")
    assert_selector "[data-gallery='theme-preview'][data-preview-appearance='dark'][data-theme='dark']"
    assert_nil evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY) if original_storage.nil?
    assert_equal original_storage, evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY) unless original_storage.nil?
    assert_no_severe_console_errors
  end

  test "popstate invalid fallback keyboard reset and clipboard announcements remain coherent" do
    visit_fresh_studio
    install_clipboard_stub

    accent = find("#customizer-accent-blue", visible: :all)
    execute_script("arguments[0].focus()", accent)
    accent.send_keys(:arrow_right)

    assert_checked_field "customizer-accent-indigo", visible: :all
    assert_includes page.current_url, "accent=indigo"

    click_button "Copy CSS"
    assert_text "CSS copied."
    assert_equal target_text("cssOutput"), evaluate_script("window.__customizerCopied")

    restore_url("?v=1&accent=amber&neutral=gray&radius=sm&density=compact&font=mono&shell=topbar")
    assert_checked_field "customizer-accent-amber", visible: :all
    assert_checked_field "customizer-shell-topbar", visible: :all
    assert_selector "[data-gallery-customizer-shell][data-variant='topbar']"
    assert_includes target_text("rubyOutput"), "layout: :topbar"

    restore_url("?v=99&accent=rose&shell=hybrid")
    assert_checked_field "customizer-accent-blue", visible: :all
    assert_checked_field "customizer-shell-sidebar", visible: :all
    assert_selector "[data-gallery='customizer-errors']:not([hidden])", text: /Version 1 defaults/

    restore_url("?v=1&accent=emerald&neutral=slate&radius=none&density=comfortable&font=humanist&shell=hybrid")
    assert_checked_field "customizer-accent-emerald", visible: :all
    assert_selector "[data-gallery='customizer-errors'][hidden]", visible: :all

    click_button "Copy share link"
    assert_text "Share link copied."
    assert_equal page.current_url, evaluate_script("window.__customizerCopied")
    assert_no_severe_console_errors
  end

  test "narrow controls follow the preview as a keyboard reachable horizontal strip" do
    resize_viewport(width: 700, height: 900)
    visit_fresh_studio

    layout = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const preview = document.querySelector('[data-gallery="customizer-preview-section"]');
        const controlsSection = document.querySelector('[data-gallery="customizer-controls-section"]');
        const controls = document.querySelector('[data-gallery="customizer-controls"]');
        const option = document.querySelector('[data-gallery="customizer-option"]');
        const style = getComputedStyle(controls);

        return {
          previewFirst: Boolean(preview.compareDocumentPosition(controlsSection) & Node.DOCUMENT_POSITION_FOLLOWING),
          gridAutoFlow: style.gridAutoFlow,
          overflowX: style.overflowX,
          optionHeight: option.getBoundingClientRect().height
        };
      })()
    JAVASCRIPT

    assert layout.fetch("previewFirst")
    assert_equal "column", layout.fetch("gridAutoFlow")
    assert_equal "auto", layout.fetch("overflowX")
    assert_operator layout.fetch("optionHeight"), :>=, 40

    first_control = find("#customizer-accent-blue", visible: :all)
    execute_script("arguments[0].focus()", first_control)
    assert_equal first_control.native, active_element
    assert_no_severe_console_errors
  end

  test "narrow preview keeps its main area usable and exposes the modal drawer" do
    resize_viewport(width: 390, height: 844)
    visit_fresh_studio

    root = "[data-gallery='theme-preview'] [data-gallery-customizer-shell]"
    sidebar = "#{root} > [data-slot='app-shell-sidebar']"
    dialog = "#{root} > [data-slot='app-shell-dialog']"
    trigger = "#{root} [data-slot='app-shell-mobile-trigger']"
    close = "#{root} [data-slot='app-shell-mobile-close']"

    layout = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const root = document.querySelector("[data-gallery='theme-preview'] [data-gallery-customizer-shell]");
        const header = root.querySelector(":scope > [data-slot='app-shell-header']");
        const sidebar = root.querySelector(":scope > [data-slot='app-shell-sidebar']");
        const dialog = root.querySelector(":scope > [data-slot='app-shell-dialog']");
        const main = root.querySelector(":scope > [data-slot='app-shell-main']");

        return {
          sidebarDisplay: getComputedStyle(sidebar).display,
          dialogOpen: dialog.open,
          mainHeight: main.getBoundingClientRect().height,
          availableHeight: root.getBoundingClientRect().height - header.getBoundingClientRect().height
        };
      })()
    JAVASCRIPT

    assert_equal "none", layout.fetch("sidebarDisplay")
    assert_equal false, layout.fetch("dialogOpen")
    assert_in_delta layout.fetch("availableHeight"), layout.fetch("mainHeight"), 1

    find(trigger).click

    assert_selector "#{root}[data-state='open']"
    assert_selector "#{dialog}[open][aria-label='Application navigation'] > [data-slot='app-shell-navigation']"
    assert_equal true, evaluate_script(
      "document.querySelector(arguments[0]).matches(':modal')",
      dialog
    )
    assert_focused close

    active_element.send_keys(:escape)

    assert_selector "#{root}[data-state='closed']"
    assert_selector "#{dialog}:not([open])", visible: :all
    assert_selector "#{sidebar} > [data-slot='app-shell-navigation']", visible: :all
    assert_equal "", evaluate_script("document.body.style.overflow")
    assert_focused trigger
    assert_no_severe_console_errors
  end

  test "every named accent keeps primary text contrast above WCAG AA in both appearances" do
    visit_fresh_studio

    Gallery::ThemePreset::CHOICES.fetch(:accent).each do |accent|
      choose_option(:accent, accent)

      %i[light dark].each do |appearance|
        choose_option(:appearance, appearance)
        sample = primary_button_contrast
        ratio = sample.fetch("ratio")

        assert_operator ratio, :>=, 4.5,
          "expected #{accent}/#{appearance} primary contrast >= 4.5, got #{ratio.round(2)} (#{sample.inspect})"
      end
    end

    assert_no_severe_console_errors
  end

  test "every neutral palette keeps muted text readable on canvas and surface" do
    visit_fresh_studio

    Gallery::ThemePreset::CHOICES.fetch(:neutral).each do |neutral|
      choose_option(:neutral, neutral)

      %i[light dark].each do |appearance|
        choose_option(:appearance, appearance)

        %w[--nk-color-canvas --nk-color-surface].each do |background|
          sample = preview_contrast(
            foreground: "--nk-color-muted-foreground",
            background:
          )
          ratio = sample.fetch("ratio")

          assert_operator ratio, :>=, 4.5,
            "expected #{neutral}/#{appearance} muted text on #{background} contrast >= 4.5, " \
              "got #{ratio.round(2)} (#{sample.inspect})"
        end
      end
    end

    assert_no_severe_console_errors
  end

  private

  def visit_fresh_studio(clear_media: true)
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "", features: []) if clear_media
    visit gallery_root_path
    execute_script("localStorage.removeItem(arguments[0])", STORAGE_KEY)
    visit gallery_customize_path
    assert_selector "[data-gallery-page='customize'][data-controller='gallery--customizer']"
    assert_selector "[data-gallery-customizer-shell][data-enhanced]"
  end

  def choose_option(attribute, value)
    find("label[for='customizer-#{attribute}-#{value}']").click
    assert_checked_field "customizer-#{attribute}-#{value}", visible: :all
  end

  def document_appearance
    evaluate_script(<<~JAVASCRIPT, STORAGE_KEY)
      ({
        preference: document.documentElement.dataset.themePreference || "system",
        theme: document.documentElement.dataset.theme,
        storage: localStorage.getItem(arguments[0])
      })
    JAVASCRIPT
  end

  def target_text(target)
    evaluate_script(
      "document.querySelector('[data-gallery--customizer-target=' + arguments[0] + ']').textContent",
      target
    )
  end

  def preview_token(name)
    evaluate_script(<<~JAVASCRIPT, name)
      getComputedStyle(document.querySelector('[data-gallery="theme-preview"]'))
        .getPropertyValue(arguments[0])
        .trim()
    JAVASCRIPT
  end

  def emulate_system_theme(theme)
    browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "",
      features: [ { name: "prefers-color-scheme", value: theme } ]
    )
  end

  def restore_url(query)
    execute_script(<<~JAVASCRIPT, query)
      const url = new URL(window.location.href);
      url.search = arguments[0];
      window.history.pushState({}, "", url);
      window.dispatchEvent(new PopStateEvent("popstate"));
    JAVASCRIPT
  end

  def install_clipboard_stub
    execute_script <<~JAVASCRIPT
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText(value) {
            window.__customizerCopied = value;
            return Promise.resolve();
          }
        }
      });
    JAVASCRIPT
  end

  def primary_button_contrast
    preview_contrast(
      selector: '[data-gallery="theme-preview"] [data-nk="button"][data-variant="primary"]',
      foreground: "color",
      background: "background-color"
    )
  end

  def preview_contrast(
    selector: '[data-gallery="theme-preview"]',
    foreground:,
    background:
  )
    wait_until(message: "preview theme transition did not settle") do
      evaluate_script <<~JAVASCRIPT
        document.querySelector('[data-gallery="theme-preview"]')
          .getAnimations({ subtree: true })
          .every((animation) => animation.playState === "finished")
      JAVASCRIPT
    end

    evaluate_script <<~JAVASCRIPT, selector, foreground, background
      (() => {
        const element = document.querySelector(arguments[0]);
        const style = getComputedStyle(element);
        const foreground = style.getPropertyValue(arguments[1]).trim();
        const background = style.getPropertyValue(arguments[2]).trim();

        const rgb = (color) => {
          const canvas = document.createElement("canvas");
          canvas.width = 1;
          canvas.height = 1;
          const context = canvas.getContext("2d", { willReadFrequently: true });
          context.fillStyle = color;
          context.fillRect(0, 0, 1, 1);
          return Array.from(context.getImageData(0, 0, 1, 1).data.slice(0, 3));
        };

        const luminance = (color) => rgb(color)
          .map((channel) => channel / 255)
          .map((channel) => channel <= 0.04045
            ? channel / 12.92
            : ((channel + 0.055) / 1.055) ** 2.4)
          .reduce((sum, channel, index) => sum + channel * [0.2126, 0.7152, 0.0722][index], 0);

        const backgroundLuminance = luminance(background);
        const foregroundLuminance = luminance(foreground);
        const lighter = Math.max(backgroundLuminance, foregroundLuminance);
        const darker = Math.min(backgroundLuminance, foregroundLuminance);
        return {
          ratio: (lighter + 0.05) / (darker + 0.05),
          background,
          foreground,
          backgroundRgb: rgb(background),
          foregroundRgb: rgb(foreground),
          theme: document.querySelector('[data-gallery="theme-preview"]').dataset.theme
        };
      })()
    JAVASCRIPT
  end
end
