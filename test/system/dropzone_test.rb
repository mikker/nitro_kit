require "application_system_test_case"

class DropzoneSystemTest < ApplicationSystemTestCase
  test "direct upload stores a signed blob id and submits after progress completes" do
    path = gallery_component_path("dropzone")
    visit path

    attach_file("gallery-dropzone-direct-input", file_fixture("profile.txt"))

    assert_selector "#gallery-dropzone-direct[data-state='success']"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-preview']", count: 1
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-name']", text: "profile.txt"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-progress'][value='100']" \
      "[aria-label='Upload progress for profile.txt']"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-status']", text: "Uploaded"
    assert_selector "#gallery-dropzone-direct input[type='hidden'][name='upload[files][]']" \
      "[data-slot='dropzone-signed-id']", visible: :all
    assert_button "Save direct upload", disabled: false
    assert_no_severe_console_errors(context: path)

    click_button "Save direct upload"

    assert_text "Received 1 file: direct upload"
  end

  test "native drop validates every file supports removal repeat selection and ordinary multipart submission" do
    path = gallery_component_path("dropzone")
    visit path
    root = "#gallery-dropzone-multipart"
    input = "#gallery-dropzone-multipart-input"

    execute_script(<<~JAVASCRIPT)
      const root = document.querySelector("#{root}");
      const transfer = new DataTransfer();
      [1, 2, 3, 4].forEach((number) => {
        transfer.items.add(new File([`file ${number}`], `dropped-${number}.txt`, { type: "text/plain" }));
      });
      root.dispatchEvent(new DragEvent("dragenter", { bubbles: true, cancelable: true, dataTransfer: transfer }));
    JAVASCRIPT
    assert_selector "#{root}[data-state='drag']"

    execute_script(<<~JAVASCRIPT)
      const root = document.querySelector("#{root}");
      const transfer = new DataTransfer();
      [1, 2, 3, 4].forEach((number) => {
        transfer.items.add(new File([`file ${number}`], `dropped-${number}.txt`, { type: "text/plain" }));
      });
      root.dispatchEvent(new DragEvent("drop", { bubbles: true, cancelable: true, dataTransfer: transfer }));
    JAVASCRIPT

    assert_selector "#{root}[data-state='error']"
    assert_selector "#{root} [data-slot='dropzone-preview']", count: 3
    assert_selector "#{root} [data-slot='dropzone-error']", text: "Choose no more than 3 files."
    assert_no_selector "#{input}[aria-invalid]"
    assert evaluate_script("document.querySelector('#{input}').checkValidity()")
    assert_equal 3, evaluate_script("document.querySelector('#{input}').files.length")
    assert_selector "#{root} [aria-label='Upload progress for dropped-1.txt']", visible: :all

    find("#{root} [aria-label='Remove dropped-1.txt']").click
    assert_selector "#{root}[data-state='success']"
    assert_selector "#{root} [data-slot='dropzone-preview']", count: 2
    assert_selector "#{root} [data-slot='dropzone-error'][hidden]", visible: :all
    assert_equal 2, evaluate_script("document.querySelector('#{input}').files.length")

    attach_file("gallery-dropzone-multipart-input", file_fixture("evidence.txt"))
    assert_selector "#{root} [data-slot='dropzone-preview']", count: 1
    assert_selector "#{root} [data-slot='dropzone-file-name']", text: "evidence.txt"
    assert_no_selector "#{input}[aria-invalid]"

    execute_script("document.querySelector('#{input}').focus()")
    assert_focused input
    assert_no_severe_console_errors(context: path)

    click_button "Submit files"
    assert_text "Received 1 file: evidence.txt"
  end

  test "invalid type can be replaced and failed direct upload can be retried" do
    path = gallery_component_path("dropzone")
    visit path

    attach_file("gallery-dropzone-multipart-input", file_fixture("rejected.json"))
    assert_selector "#gallery-dropzone-multipart[data-state='error']"
    assert_selector "#gallery-dropzone-multipart-error", text: "rejected.json is not an accepted file type."
    assert_equal 0, evaluate_script("document.querySelector('#gallery-dropzone-multipart-input').files.length")

    attach_file("gallery-dropzone-multipart-input", file_fixture("profile.txt"))
    assert_selector "#gallery-dropzone-multipart[data-state='success']"
    assert_selector "#gallery-dropzone-multipart-error[hidden]", visible: :all
    assert_no_selector "#gallery-dropzone-multipart-input[aria-invalid]"

    execute_script("document.querySelector('#gallery-dropzone-direct-input').dataset.directUploadUrl = '/missing-direct-upload'")
    attach_file("gallery-dropzone-direct-input", file_fixture("profile.txt"))
    assert_selector "#gallery-dropzone-direct[data-state='error']"
    assert_selector "#gallery-dropzone-direct-error", text: /profile\.txt could not be uploaded/
    assert_button "Save direct upload", disabled: false

    browser_console_entries
    execute_script(<<~JAVASCRIPT)
      document.querySelector("#gallery-dropzone-direct-input").dataset.directUploadUrl =
        "#{rails_direct_uploads_path}";
    JAVASCRIPT
    attach_file("gallery-dropzone-direct-input", file_fixture("evidence.txt"))

    assert_selector "#gallery-dropzone-direct[data-state='success']"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-preview']", count: 1
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-name']", text: "evidence.txt"
    assert_selector "#gallery-dropzone-direct-error[hidden]", visible: :all
    assert_no_selector "#gallery-dropzone-direct-input[aria-invalid]"
    assert_no_severe_console_errors(context: path)
  end

  test "invalid files do not displace later valid direct uploads and rejection messaging stays nonblocking" do
    path = gallery_component_path("dropzone")
    visit path

    execute_script(<<~JAVASCRIPT)
      const input = document.querySelector("#gallery-dropzone-direct-input");
      const transfer = new DataTransfer();
      transfer.items.add(new File(["rejected"], "rejected.json", { type: "application/json" }));
      transfer.items.add(new File(["accepted one"], "accepted-one.txt", { type: "text/plain" }));
      transfer.items.add(new File(["accepted two"], "accepted-two.txt", { type: "text/plain" }));
      input.files = transfer.files;
      input.dispatchEvent(new Event("change", { bubbles: true }));
    JAVASCRIPT

    assert_selector "#gallery-dropzone-direct[data-state='error']"
    assert_selector "#gallery-dropzone-direct-error", text: "rejected.json is not an accepted file type."
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-preview']", count: 2
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-name']", text: "accepted-one.txt"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-name']", text: "accepted-two.txt"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-file-status']", text: "Uploaded", count: 2
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-signed-id']", count: 2, visible: :all
    assert_no_selector "#gallery-dropzone-direct-input[aria-invalid]"
    assert evaluate_script("document.querySelector('#gallery-dropzone-direct-input').checkValidity()")
    assert_button "Save direct upload", disabled: false
    assert_no_severe_console_errors(context: path)

    click_button "Save direct upload"
    assert_text "Received 2 files: direct upload, direct upload"
  end

  test "two Dropzones retain independent locks for a shared form through cancellation and teardown" do
    path = gallery_component_path("dropzone")
    visit path

    lock_state = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const primary = document.querySelector("#gallery-dropzone-shared-primary");
        const secondary = document.querySelector("#gallery-dropzone-shared-secondary");
        const primaryInput = document.querySelector("#gallery-dropzone-shared-primary-input");
        const secondaryInput = document.querySelector("#gallery-dropzone-shared-secondary-input");
        const submit = document.querySelector("#gallery-dropzone-shared-submit");
        const initiallyDisabled = document.querySelector("#gallery-dropzone-shared-disabled-submit");

        [
          [primaryInput, "primary.txt"],
          [secondaryInput, "secondary.txt"]
        ].forEach(([input, name]) => {
          const transfer = new DataTransfer();
          transfer.items.add(new File([new Uint8Array(256 * 1024)], name, { type: "text/plain" }));
          input.files = transfer.files;
          input.dispatchEvent(new Event("change", { bubbles: true }));
        });

        const disabledDuringParallelUploads = submit.disabled;
        const disabledControlDuringUploads = initiallyDisabled.disabled;
        const primaryController = window.Stimulus.getControllerForElementAndIdentifier(primary, "nk--dropzone");
        primaryController.remove({
          currentTarget: primary.querySelector("[data-slot='dropzone-remove-control']")
        });
        const disabledAfterPrimaryCancellation = submit.disabled;

        document.dispatchEvent(new Event("turbo:before-cache"));

        return {
          disabledDuringParallelUploads,
          disabledControlDuringUploads,
          disabledAfterPrimaryCancellation,
          disabledAfterTeardown: submit.disabled,
          disabledControlAfterTeardown: initiallyDisabled.disabled,
          primaryFilesAfterTeardown: primaryInput.files.length,
          secondaryFilesAfterTeardown: secondaryInput.files.length
        };
      })()
    JAVASCRIPT

    assert lock_state.fetch("disabledDuringParallelUploads")
    assert lock_state.fetch("disabledControlDuringUploads")
    assert lock_state.fetch("disabledAfterPrimaryCancellation")
    refute lock_state.fetch("disabledAfterTeardown")
    assert lock_state.fetch("disabledControlAfterTeardown")
    assert_equal 0, lock_state.fetch("primaryFilesAfterTeardown")
    assert_equal 0, lock_state.fetch("secondaryFilesAfterTeardown")
    assert_selector "#gallery-dropzone-shared-primary[data-state='idle']"
    assert_selector "#gallery-dropzone-shared-secondary[data-state='idle']"
    assert_no_severe_console_errors(context: path)
  end

  test "cancel removal restores form controls and Turbo cache teardown restores clean markup" do
    path = gallery_component_path("dropzone")
    visit path

    cancellation = evaluate_script(<<~JAVASCRIPT)
      (() => {
        const root = document.querySelector("#gallery-dropzone-direct");
        const input = document.querySelector("#gallery-dropzone-direct-input");
        const submit = document.querySelector("#gallery-dropzone-direct-submit");
        const transfer = new DataTransfer();
        transfer.items.add(
          new File([new Uint8Array(256 * 1024)], "cancel-me.txt", { type: "text/plain" })
        );
        input.files = transfer.files;
        input.dispatchEvent(new Event("change", { bubbles: true }));
        const disabledDuringUpload = submit.disabled;
        const controller = window.Stimulus.getControllerForElementAndIdentifier(root, "nk--dropzone");
        controller.remove({
          currentTarget: root.querySelector("[data-slot='dropzone-remove-control']")
        });

        return {
          disabledDuringUpload,
          disabledAfterRemoval: submit.disabled,
          fileCount: input.files.length
        };
      })()
    JAVASCRIPT

    assert cancellation.fetch("disabledDuringUpload")
    refute cancellation.fetch("disabledAfterRemoval")
    assert_equal 0, cancellation.fetch("fileCount")
    assert_selector "#gallery-dropzone-direct[data-state='idle']"
    assert_selector "#gallery-dropzone-direct [data-slot='dropzone-preview-list'][hidden]", visible: :all
    assert_no_selector "#gallery-dropzone-direct [data-slot='dropzone-signed-id']", visible: :all

    attach_file("gallery-dropzone-multipart-input", file_fixture("profile.txt"))
    assert_selector "#gallery-dropzone-multipart[data-state='success']"
    execute_script("document.dispatchEvent(new Event('turbo:before-cache'))")

    assert_selector "#gallery-dropzone-multipart[data-state='idle']"
    assert_selector "#gallery-dropzone-multipart [data-slot='dropzone-preview-list'][hidden]", visible: :all
    assert_no_selector "#gallery-dropzone-multipart [data-slot='dropzone-preview']", visible: :all
    assert_selector "#gallery-dropzone-multipart-status", text: "No files selected."
    assert_equal 0, evaluate_script("document.querySelector('#gallery-dropzone-multipart-input').files.length")

    within("[data-gallery='sidebar']") { click_link("Button") }
    within("[data-gallery='sidebar']") { click_link("Dropzone") }

    assert_selector "#gallery-dropzone-multipart[data-state='idle']"
    assert_selector "#gallery-dropzone-multipart [data-slot='dropzone-preview-list'][hidden]", visible: :all
    assert_no_severe_console_errors(context: path)
  end

  test "disconnect preserves native files while Turbo cache teardown clears them" do
    path = gallery_component_path("dropzone")
    visit path
    root = "#gallery-dropzone-multipart"
    input = "#gallery-dropzone-multipart-input"

    attach_file("gallery-dropzone-multipart-input", file_fixture("evidence.txt"))
    assert_selector "#{root}[data-state='success']"

    execute_script("document.querySelector(arguments[0]).removeAttribute('data-controller')", root)

    assert_equal 1, evaluate_script("document.querySelector(arguments[0]).files.length", input)
    assert_selector "#{root} [data-slot='dropzone-preview-list'][hidden]", visible: :all
    assert_selector "#{root} [data-slot='dropzone-status']", text: "1 file selected."

    click_button "Submit files"
    assert_text "Received 1 file: evidence.txt"

    visit path
    attach_file("gallery-dropzone-multipart-input", file_fixture("evidence.txt"))
    execute_script("document.dispatchEvent(new Event('turbo:before-cache'))")

    assert_equal 0, evaluate_script("document.querySelector(arguments[0]).files.length", input)
    assert_selector "#{root}[data-state='idle']"
    assert_no_severe_console_errors(context: path)
  end
end
