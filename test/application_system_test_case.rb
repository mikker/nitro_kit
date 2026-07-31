require "test_helper"
require "capybara/rails"
require "selenium/webdriver"
require_relative "system/support/browser_helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include BrowserHelpers

  driven_by :selenium, using: :chrome, screen_size: [ 1440, 1200 ] do |options|
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-background-networking")
    options.logging_prefs = { browser: "ALL" }
  end

  setup do
    browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    # Headless Chrome otherwise reports document.hasFocus() == false for a
    # backgrounded target and silently drops focus/focusin events.
    browser.execute_cdp("Emulation.setFocusEmulationEnabled", enabled: true)
    browser.execute_cdp(
      "Emulation.setEmulatedMedia",
      features: [
        { name: "hover", value: "hover" },
        { name: "any-hover", value: "hover" },
        { name: "pointer", value: "fine" },
        { name: "any-pointer", value: "fine" }
      ]
    )
    resize_viewport(width: 1440, height: 1200)
  end

  Capybara.default_max_wait_time = 5
end
