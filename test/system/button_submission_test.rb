require "application_system_test_case"

class ButtonSubmissionTest < ApplicationSystemTestCase
  test "Turbo submission feedback keeps the original label and dims the button" do
    visit gallery_component_path("button")
    button = find("#gallery-button-turbo-submit")
    width_before_submission = button.rect.width

    execute_script <<~JAVASCRIPT
      document.addEventListener("turbo:submit-start", () => {
        const button = document.querySelector("#gallery-button-turbo-submit");
        window.__nitroButtonSubmission = {
          disabled: button.disabled,
          label: button.innerText,
          width: button.getBoundingClientRect().width
        };
      }, { once: true });
    JAVASCRIPT
    button.click

    wait_until { evaluate_script("window.__nitroButtonSubmission") }
    submission = evaluate_script("window.__nitroButtonSubmission")

    assert submission.fetch("disabled")
    assert_equal "Save workspace changes", submission.fetch("label")
    assert_in_delta width_before_submission, submission.fetch("width"), 0.5
  end

  test "opt-in submission spinner appears after 1 second and expands the button" do
    visit gallery_component_path("button")
    button = find("#gallery-button-turbo-spinner-submit")
    width_before_submission = button.rect.width

    button.click

    assert_selector "#gallery-button-turbo-spinner-submit[disabled][aria-busy='true']"
    assert_no_selector(
      "#gallery-button-turbo-spinner-submit [data-slot='button-submission-spinner'][data-state='visible']",
      wait: 0.75
    )
    assert_selector "#gallery-button-turbo-spinner-submit [data-slot='button-submission-spinner'][data-state='visible']"
    assert_equal "Save workspace changes", button.text
    assert_operator button.rect.width, :>, width_before_submission
  end
end
