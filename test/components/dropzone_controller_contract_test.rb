require "test_helper"

class DropzoneControllerContractTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root.join("app/javascript/controllers/nk")
  CONTROLLER = ROOT.join("dropzone_controller.js")
  DIRECT_UPLOAD = ROOT.join("dropzone/direct_upload.js")
  FILE_RULES = ROOT.join("dropzone/file_rules.js")
  FORM_LOCK = ROOT.join("dropzone/form_submit_lock.js")

  test "keeps the controller focused on native selection preview and state" do
    source = CONTROLLER.read

    assert_includes source, "new DataTransfer()"
    assert_includes source, "event.dataTransfer.files"
    assert_includes source, "URL.createObjectURL"
    assert_includes source, "URL.revokeObjectURL"
    assert_includes source, 'import DirectUploadSession from "controllers/nk/dropzone/direct_upload"'
    assert_includes source, 'from "controllers/nk/dropzone/file_rules"'
    assert_includes source, 'from "controllers/nk/dropzone/form_submit_lock"'
    refute_includes source, "@rails/activestorage"
    refute_includes source, "addEventListener"
    refute_includes source, "formSubmitLocks"
    refute_includes source, "js_options"
  end

  test "gives Active Storage request and progress teardown one owner" do
    source = DIRECT_UPLOAD.read

    assert_includes source, 'import { DirectUpload } from "@rails/activestorage"'
    assert_includes source, "directUploadWillCreateBlobWithXHR"
    assert_includes source, "directUploadWillStoreFileWithXHR"
    assert_includes source, 'addEventListener("progress", this.progressListener)'
    assert_includes source, "removeEventListener("
    assert_includes source, "this.request?.abort()"
    assert_includes source, "if (this.cancelled) return"
    assert_match(/if \(this\.cancelled\) \{\s+queueMicrotask\(\(\) => request\.abort\(\)\)/, source)
  end

  test "isolates file policy and shared form locking from DOM orchestration" do
    rules = FILE_RULES.read
    lock = FORM_LOCK.read

    assert_includes rules, "export function validateFiles"
    assert_includes rules, "export function rejectionMessage"
    assert_includes rules, "export function formatBytes"
    assert_match(/accepted:\s+selections\s+\.filter/, rules)
    assert_includes rules, "rejected: selections.filter"

    assert_includes lock, "const locks = new WeakMap()"
    assert_includes lock, "owners: new Set()"
    assert_includes lock, "lock.owners.add(owner)"
    assert_includes lock, "lock.owners.delete(owner)"
    assert_includes lock, "if (!lock.controls.has(control))"
  end

  test "separates disconnect fallback from destructive Turbo cache cleanup" do
    source = CONTROLLER.read

    assert_includes source, "this.release({ clearInput: false })"
    assert_includes source, "this.release({ clearInput: true })"
    assert_includes source, 'if (clearInput) input.value = ""'
    assert_includes source, ':scope > [data-slot="dropzone-input"]'
    assert_includes source, "const files = Array.from(this.inputTarget.files)"
    assert_includes source, "if (files.length > 0) this.replaceFiles(files)"
    assert_includes source, "event.target !== form"
    assert_includes source, "restoreSubmitControls()"
  end

  test "pins Active Storage and packages every Dropzone source" do
    importmap = NitroKit::Engine.root.join("config/importmap.rb").read
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    assert_includes importmap, 'pin "@rails/activestorage", to: "activestorage.esm.js"'
    assert_includes files, "app/components/nitro_kit/dropzone.rb"
    assert_includes files, "app/javascript/controllers/nk/dropzone_controller.js"
    assert_includes files, "app/javascript/controllers/nk/dropzone/direct_upload.js"
    assert_includes files, "app/javascript/controllers/nk/dropzone/file_rules.js"
    assert_includes files, "app/javascript/controllers/nk/dropzone/form_submit_lock.js"
    assert_includes files, "src/stylesheets/nitro_kit/components/dropzone.css"
  end
end
