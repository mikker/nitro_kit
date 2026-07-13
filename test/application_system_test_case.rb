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

  Capybara.default_max_wait_time = 5
end
