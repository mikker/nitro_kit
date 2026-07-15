require "application_system_test_case"

class AppearanceSystemTest < ApplicationSystemTestCase
  STORAGE_KEY = NitroKit::AppearanceBootstrap::STORAGE_KEY

  teardown do
    execute_script("try { localStorage.removeItem(arguments[0]) } catch (_error) {}", STORAGE_KEY)
    browser.execute_cdp("Emulation.setEmulatedMedia", media: "", features: [])
  end

  test "explicit preference persists through reload and Turbo while every picker stays synchronized" do
    visit_without_saved_preference(gallery_component_path("appearance-picker"))

    picker_count = all("[data-nk='appearance-picker']").size
    assert_operator picker_count, :>=, 3

    find("#gallery-appearance-dark").click
    assert_document_appearance(preference: "dark", theme: "dark")
    assert_synchronized_pickers("dark", count: picker_count)
    assert_equal "dark", evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY)

    execute_script <<~JAVASCRIPT
      window.__removedAppearancePicker = document.querySelector("#gallery-appearance-card-control");
    JAVASCRIPT

    within("[data-gallery='sidebar']") { click_link("Button", exact: true) }

    assert_current_path gallery_component_path("button")
    assert_document_appearance(preference: "dark", theme: "dark")
    assert_equal false, evaluate_script("window.__removedAppearancePicker.isConnected")
    assert_equal "dark", evaluate_script("window.__removedAppearancePicker.dataset.state")

    execute_script <<~JAVASCRIPT
      window.__appearanceChangeCount = 0;
      window.addEventListener("nitro-kit:appearance-change", () => window.__appearanceChangeCount += 1);
    JAVASCRIPT
    find("#gallery-appearance-light").click

    assert_document_appearance(preference: "light", theme: "light")
    assert_equal 1, evaluate_script("window.__appearanceChangeCount")
    assert_equal "dark", evaluate_script("window.__removedAppearancePicker.dataset.state")

    within("[data-gallery='sidebar']") { click_link("Appearance picker", exact: true) }
    reconnected_count = all("[data-nk='appearance-picker']").size
    assert_synchronized_pickers("light", count: reconnected_count)

    browser.navigate.refresh

    assert_document_appearance(preference: "light", theme: "light")
    assert_synchronized_pickers("light", count: reconnected_count)
    assert_no_severe_console_errors
  end

  test "system preference follows live media changes without any picker while explicit preference does not" do
    clear_saved_preference
    emulate_system_theme("dark")
    visit gallery_component_path("appearance-picker")

    assert_document_appearance(preference: "system", theme: "dark")
    emulate_system_theme("light")
    assert_document_appearance(preference: "system", theme: "light")

    execute_script("document.querySelectorAll('[data-nk=appearance-picker]').forEach((picker) => picker.remove())")
    assert_selector "[data-nk='appearance-picker']", count: 0

    emulate_system_theme("dark")
    assert_document_appearance(preference: "system", theme: "dark")

    browser.navigate.refresh
    find("#gallery-appearance-dark").click
    emulate_system_theme("light")

    assert_document_appearance(preference: "dark", theme: "dark")
    assert_no_severe_console_errors
  end

  test "storage events synchronize multiple pickers and repeated bootstrap execution remains singular" do
    visit_without_saved_preference(gallery_component_path("appearance-picker"))
    picker_count = all("[data-nk='appearance-picker']").size

    execute_script(<<~JAVASCRIPT, STORAGE_KEY)
      window.localStorage.setItem(arguments[0], "dark");
      window.dispatchEvent(new StorageEvent("storage", {
        key: arguments[0],
        newValue: "dark",
        storageArea: window.localStorage
      }));
    JAVASCRIPT

    assert_document_appearance(preference: "dark", theme: "dark")
    assert_synchronized_pickers("dark", count: picker_count)

    script_body = evaluate_script(
      "document.querySelector('script[data-nk-appearance-default]').textContent"
    )
    assert_equal NitroKit::AppearanceBootstrap::SCRIPT, script_body

    execute_script <<~JAVASCRIPT, script_body
      window.__appearanceChangeCount = 0;
      window.addEventListener("nitro-kit:appearance-change", () => window.__appearanceChangeCount += 1);
      window.eval(arguments[0]);
      window.eval(arguments[0]);
    JAVASCRIPT

    assert_equal 0, evaluate_script("window.__appearanceChangeCount")

    execute_script <<~JAVASCRIPT
      window.dispatchEvent(new CustomEvent("nitro-kit:appearance-request", {
        detail: { preference: "light" }
      }));
    JAVASCRIPT

    assert_document_appearance(preference: "light", theme: "light")
    assert_equal 1, evaluate_script("window.__appearanceChangeCount")
    assert_synchronized_pickers("light", count: picker_count)
    assert_no_severe_console_errors
  end

  test "malformed and denied storage fall back safely while in-document changes still work" do
    visit gallery_root_path
    execute_script("localStorage.setItem(arguments[0], 'sepia')", STORAGE_KEY)
    browser.navigate.refresh

    assert_document_appearance(preference: "system", theme: resolved_system_theme)
    assert_equal "sepia", evaluate_script("localStorage.getItem(arguments[0])", STORAGE_KEY)
    assert_no_severe_console_errors

    injection = browser.execute_cdp(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JAVASCRIPT
        Storage.prototype.getItem = function () { throw new DOMException("denied", "SecurityError") };
        Storage.prototype.setItem = function () { throw new DOMException("denied", "SecurityError") };
      JAVASCRIPT
    )

    browser.navigate.refresh

    assert_document_appearance(preference: "system", theme: resolved_system_theme)
    find("#gallery-appearance-dark").click
    assert_document_appearance(preference: "dark", theme: "dark")
    assert_no_severe_console_errors
  ensure
    identifier = injection&.fetch("identifier", nil)
    browser.execute_cdp("Page.removeScriptToEvaluateOnNewDocument", identifier:) if identifier
  end

  private

  def visit_without_saved_preference(path)
    clear_saved_preference
    visit path
  end

  def clear_saved_preference
    visit gallery_root_path
    execute_script("localStorage.removeItem(arguments[0])", STORAGE_KEY)
  end

  def emulate_system_theme(theme)
    browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      media: "",
      features: [ { name: "prefers-color-scheme", value: theme } ]
    )
  end

  def assert_document_appearance(preference:, theme:)
    assert_selector "html[data-theme-preference='#{preference}'][data-theme='#{theme}']"
  end

  def assert_synchronized_pickers(preference, count:)
    assert_selector "[data-nk='appearance-picker'][data-state='#{preference}']", count: count
    assert_selector "[data-nk='appearance-picker'] input[value='#{preference}']:checked", count: count
  end

  def resolved_system_theme
    evaluate_script("matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'")
  end
end
