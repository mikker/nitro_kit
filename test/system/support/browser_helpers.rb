module BrowserHelpers
  def browser
    page.driver.browser
  end

  def browser_console_entries
    chrome? ? browser.logs.get(:browser) : []
  end

  def chrome?
    ApplicationSystemTestCase::BROWSER == :chrome
  end

  def severe_console_entries
    browser_console_entries.select { |entry| entry.level == "SEVERE" }
  end

  def assert_no_severe_console_errors(context: nil)
    errors = severe_console_entries
    return assert_empty(errors) if errors.empty?

    location = context || page.current_url
    messages = errors.map { |entry| "[#{entry.level}] #{entry.message}" }.join("\n")
    flunk("Severe browser console errors at #{location}:\n#{messages}")
  end

  def wait_until(timeout: Capybara.default_max_wait_time, message: nil, &condition)
    Selenium::WebDriver::Wait.new(timeout:, message:).until(&condition)
  end

  def evaluate_script(script, *arguments)
    page.evaluate_script(script, *arguments)
  end

  def execute_script(script, *arguments)
    page.execute_script(script, *arguments)
  end

  def resize_viewport(width:, height:)
    browser.manage.window.resize_to(width, height)
  end

  def active_element
    browser.switch_to.active_element
  end

  def click_gallery_navigation_link(title)
    unless has_selector?("#gallery-navigation", visible: true, wait: 0)
      find("#gallery-shell [data-slot='app-shell-mobile-trigger']").click
      assert_selector "#gallery-shell > [data-slot='app-shell-dialog'][open] #gallery-navigation"
    end

    within("#gallery-navigation") { click_link(title, exact: true) }
  end

  def assert_focused(selector, **find_options)
    element = find(selector, **find_options)

    wait_until(message: "#{selector.inspect} did not receive browser focus") do
      element.native == active_element
    end
    assert_equal element.native, active_element, "Expected #{selector.inspect} to have browser focus"
    element
  end
end
