require "application_system_test_case"

class ComboboxSystemTest < ApplicationSystemTestCase
  ROOT = "#gallery-combobox-release-labels".freeze
  INPUT = "#gallery-combobox-release-labels-input".freeze
  RESULT = "#{ROOT} [data-slot='combobox-listbox'] > [data-slot='combobox-option']".freeze
  CHIP = "#{ROOT} [data-slot='combobox-selections'] > [data-slot='combobox-selection']".freeze

  test "remote relation picker keeps searched and created selections through an invalid re-render" do
    path = visit_combobox_page
    created_name = "Nightly #{SecureRandom.hex(3)}"

    assert_selector "#{ROOT}[data-enhanced='true']"
    find(INPUT).click
    assert_selector "#{ROOT}[data-state='open']"
    assert_selector RESULT, minimum: 8

    find(INPUT).set("bug")
    assert_results ROOT, "Bug"
    assert_selector "#{ROOT} [data-slot='combobox-status']", text: "1 option available.", visible: :all
    find(RESULT, text: "Bug").click

    find(INPUT).set("perf")
    assert_results ROOT, "Performance"
    find(INPUT).send_keys(:arrow_down, :enter)
    assert_selector CHIP, count: 2
    assert_selector "#{RESULT}[aria-selected='true']", text: "Performance"

    find(INPUT).set(created_name)
    action = "#{ROOT} [data-slot='combobox-listbox'] > [data-slot='combobox-action']"
    assert_selector action, text: "Create label “#{created_name}”"
    assert_no_selector RESULT
    find(action).click

    assert_selector CHIP, count: 3
    assert_equal [ "Bug", "Performance", created_name ], chip_labels
    assert_selector "#{RESULT}[aria-selected='true']", text: created_name
    assert_no_selector action
    submitted = submitted_label_ids
    assert_equal "", submitted.first
    assert_equal 4, submitted.size

    find("#gallery-combobox-release-save").click

    assert_selector "#gallery-combobox-release-title[aria-invalid='true']"
    assert_selector "#gallery-combobox-release-frame [data-slot='field-error']", text: "Title can't be blank"
    assert_selector CHIP, count: 3
    assert_equal [ "Bug", "Performance", created_name ], chip_labels
    assert_equal submitted, submitted_label_ids
    assert_selector "#{ROOT}[data-enhanced='true']"

    find("#{CHIP}[data-value='7'] [data-slot='combobox-remove']").click
    assert_equal [ "Bug", created_name ], chip_labels
    assert_focused "#{CHIP}:last-child [data-slot='combobox-remove']"

    find("#gallery-combobox-release-title").set("Spring release")
    find("#gallery-combobox-release-save").click
    assert_selector "#gallery-combobox-release-frame [data-nk='alert']", text: "Labels: Bug and #{created_name}"
    assert_no_selector CHIP
    assert_only_expected_console_errors(path, "/gallery/combobox_release")
  end

  test "an older remote response never overwrites newer results" do
    path = visit_combobox_page
    assert_selector "#{ROOT}[data-enhanced='true']"

    execute_script(<<~JAVASCRIPT)
      const original = window.fetch;
      window.__comboboxQueries = [];
      window.fetch = (input, init = {}) => {
        const url = new URL(String(input), document.baseURI);
        const query = url.searchParams.get("query");
        window.__comboboxQueries.push(query);
        // Ignore the abort signal so the stale response really does arrive late.
        const { signal, ...rest } = init;
        const response = original(input, rest);
        if (query !== "sec") return response;

        return new Promise((resolve) => setTimeout(() => {
          resolve(response);
          setTimeout(() => { window.__staleDelivered = true; }, 50);
        }, 600));
      };
    JAVASCRIPT

    find(INPUT).set("sec")
    wait_until(message: "slow search was not sent") do
      evaluate_script("window.__comboboxQueries.includes('sec')")
    end
    find(INPUT).set("bug")
    assert_results ROOT, "Bug"

    wait_until(message: "stale response was not delivered") { evaluate_script("window.__staleDelivered === true") }
    assert_results ROOT, "Bug"
    assert_no_selector RESULT, text: "Security"
    assert_no_selector "#{ROOT} [data-slot='combobox-listbox'][aria-busy]", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "remote single selection, failure feedback, and chip keyboard removal" do
    path = visit_combobox_page

    single = "#gallery-combobox-remote-single"
    single_input = "#{single}-input"
    single_value = "#{single}-value"
    assert_selector "#{single}[data-enhanced='true']"
    assert_equal "8", find(single_value, visible: :all).value

    find(single_input).set("design")
    assert_equal "", find(single_value, visible: :all).value
    assert_selector "#{single_input}[aria-invalid='true']"
    assert_results single, "Design"
    find(single_input).send_keys(:arrow_down, :enter)
    assert_equal "4", find(single_value, visible: :all).value
    assert_equal "Design", find(single_input).value
    assert_selector "#{single}[data-state='closed']"
    assert_selector "#{single_input}[aria-invalid='false']"

    failing = "#gallery-combobox-remote-error"
    find("#{failing}-input").set("any")
    assert_selector "#{failing} [data-slot='combobox-message'][data-state='error']",
      text: "Results could not be loaded. Try again."
    assert_selector "#{failing} [data-slot='combobox-status']", text: "Results could not be loaded.", visible: :all
    find("#{failing}-input").send_keys(:enter)
    assert_selector "#{failing}[data-state='open']"
    find("#{failing}-input").send_keys(:escape)
    find("#{failing}-input").set("")
    find("#{failing}-input").send_keys(:backspace)
    assert_no_selector "#{failing} [data-slot='combobox-selections'] > [data-slot='combobox-selection']"

    required = "#gallery-combobox-remote-required-input"
    assert_selector "#{required}[aria-invalid='true']"
    assert_selector "#gallery-combobox-remote-disabled [data-slot='combobox-remove'][disabled]", count: 2
    assert_only_expected_console_errors(path, "unavailable=1")
  end

  private

  # Starts from a clean console log so a late failure from an earlier test's
  # deliberately unavailable search cannot leak into this one.
  def visit_combobox_page
    path = gallery_component_path("combobox")
    visit path
    browser_console_entries
    path
  end

  # Deliberate 422 and 503 responses log as failed resource loads.
  def assert_only_expected_console_errors(path, *expected)
    errors = severe_console_entries.reject do |entry|
      expected.any? { |fragment| entry.message.include?(fragment) }
    end
    assert_empty errors.map(&:message), "Unexpected severe console errors at #{path}"
  end

  def assert_results(root, *labels)
    selector = "#{root} [data-slot='combobox-listbox'] > [data-slot='combobox-option'] [data-slot='combobox-option-label']"
    wait_until(message: "expected results #{labels.inspect}") do
      all(selector, wait: false).map(&:text) == labels
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      false
    end
  end

  def chip_labels
    all("#{CHIP} [data-slot='combobox-selection-label']").map(&:text)
  end

  def submitted_label_ids
    evaluate_script(<<~JAVASCRIPT)
      Array.from(new FormData(document.querySelector("#gallery-combobox-release-form")).getAll("release[label_ids][]"))
    JAVASCRIPT
  end
end
