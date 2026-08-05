require "test_helper"

class BrowserConfigurationTest < ActiveSupport::TestCase
  SYSTEM_TEST_CASE = File.expand_path("../application_system_test_case.rb", __dir__)

  test "system tests expose the supported browser selector" do
    source = File.read(SYSTEM_TEST_CASE)

    assert_includes source, 'ENV.fetch("BROWSER", "chrome")'
    assert_includes source, "SUPPORTED_BROWSERS = %i[chrome firefox safari]"
    assert_includes source, "driven_by :selenium, using: BROWSER"
  end

  test "CDP setup is restricted to Chrome" do
    source = File.read(SYSTEM_TEST_CASE)

    cdp_setup = source[/setup do\n(.*?)\n    end/m, 1]
    assert_includes cdp_setup, "if BROWSER == :chrome"
    assert_equal 2, cdp_setup.scan("execute_cdp").length
  end

  test "priority browser lane has one executable manifest" do
    smoke = File.expand_path("../../bin/browser-smoke", __dir__)
    source = File.read(smoke)

    assert File.executable?(smoke)
    assert_includes source, "PARALLEL_WORKERS=1"
    refute_includes source, "test:system"
    assert_includes source, "interactive_components_test.rb"
    assert_includes source, "command_palette_test.rb"
    assert_includes source, "appearance_test.rb"
    assert_includes source, "hotwire_lifecycle_test.rb"
    assert_includes source, "typeset_test.rb"
    assert_includes source, "input_field_test.rb"
    assert_includes source, "form_builder_rails_test.rb"
  end

  test "workflow keeps browser setup and version claims aligned" do
    workflow = File.expand_path("../../.github/workflows/ci.yml", __dir__)
    source = File.read(workflow)

    assert_includes source, "browser: [chrome, firefox]"
    assert_includes source, "browser-actions/setup-firefox@v1"
    refute_match(/apt-get install[^\n]*\bfirefox\b/, source)
    assert_includes source, "sudo -n safaridriver --enable"
    assert_includes source, 'PARALLEL_WORKERS: "1"'
    assert_equal 2, source.scan("bin/browser-smoke").length
    assert_equal 1, source.scan("run: xvfb-run --auto-servernum bin/rails test:system").length
    refute_includes source, "timeout bin/browser-smoke"

    browser_support = File.expand_path("../../docs/browser_support.md", __dir__)
    matrix = File.read(browser_support)
    assert_includes matrix, "Chrome desktop  | Chrome 128           | Chrome 151"
    assert_includes matrix, "Edge desktop    | Edge 128             | Edge 151"
    assert_includes matrix, "Chrome Android  | Chrome 128           | Chrome 151 on Android"
    assert_includes matrix, "Firefox desktop | Firefox 128 ESR      | Firefox 153"
  end
end
