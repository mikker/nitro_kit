module BrowserHelpers
  def browser
    page.driver.browser
  end

  def browser_console_entries
    browser.logs.get(:browser)
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

  # Gallery categories are collapsed `details` disclosures unless they hold the
  # current entry, so reaching another entry means opening its category first.
  # Gallery categories are collapsed `details` disclosures unless they hold the
  # current entry, and a Turbo Drive visit re-renders the sidebar, so keep
  # expanding until the requested entry is actually reachable.
  def click_gallery_navigation_link(title)
    link = "//aside[@data-gallery='sidebar']//a[normalize-space()=#{title.inspect}]"

    wait_until(message: "Expected the gallery sidebar to expose #{title.inspect}") do
      execute_script(<<~JAVASCRIPT)
        document
          .querySelectorAll("[data-gallery='sidebar'] details")
          .forEach((category) => { category.open = true });
      JAVASCRIPT
      has_selector?(:xpath, link, wait: 0)
    end

    find(:xpath, link).click
  end

  def assert_focused(selector, **find_options)
    element = find(selector, **find_options)

    assert_equal element.native, active_element, "Expected #{selector.inspect} to have browser focus"
    element
  end
end
