require "test_helper"

Capybara.server = :puma, {Silent: true}

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by(
    :cuprite,
    using: :chrome,
    screen_size: [1400, 1400],
    options: {
      js_errors: true,
      headless: !ENV["HEADLESS"].in?(%w[n 0 no false]),
      process_timeout: 5,
      timeout: 5,
      browser_options: {:"no-sandbox" => nil}
    }
  )
end
