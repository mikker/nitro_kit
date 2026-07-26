require "test_helper"

# The wizard's observable behavior — preview, export, URL state, clipboard, and
# appearance isolation — is covered by test/system/customization_studio_test.rb
# and test/integration/customization_gallery_test.rb. This contract only guards
# the boundaries a reader cannot see from the outside: the controller reacts
# from server-owned schema, never builds markup or evaluates source, keeps
# document appearance and storage untouched, and releases what it retains.
class CustomizerControllerContractTest < ActiveSupport::TestCase
  CONTROLLER = NitroKit::Engine.root.join(
    "test/dummy/app/javascript/controllers/gallery/customizer_controller.js"
  )

  test "reacts from server-owned schema without constructing markup" do
    source = CONTROLLER.read

    assert_includes source, "schema: Object"
    assert_includes source, "this.schemaValue"
    refute_includes source, "innerHTML"
    refute_includes source, "insertAdjacentHTML"
    refute_includes source, "createElement"
    refute_includes source, "eval("
  end

  test "keeps readable URL state without opaque encoding or history entries" do
    source = CONTROLLER.read

    assert_includes source, "searchParams"
    assert_includes source, "replaceState"
    refute_includes source, "pushState"
    refute_includes source, "btoa"
    refute_includes source, "atob"
  end

  test "isolates preview appearance and cleans retained resources" do
    source = CONTROLLER.read

    assert_includes source, "matchMedia"
    assert_includes source, 'addEventListener("change", this.onSystemAppearanceChange)'
    assert_includes source, 'removeEventListener("change", this.onSystemAppearanceChange)'
    assert_includes source, "clearTimeout"
    refute_includes source, "localStorage"
    refute_includes source, "sessionStorage"
    refute_includes source, "document.documentElement"
    refute_includes source, "nitro-kit:appearance"
    refute_includes source, "dispatchEvent"
  end

  test "guards asynchronous clipboard announcements by connection and revision" do
    source = CONTROLLER.read

    assert_includes source, "this.copyAttempt"
    assert_includes source, "this.connected"
    assert_includes source, "navigator.clipboard"
  end

  test "exports only documented public tokens" do
    source = CONTROLLER.read

    assert_includes source, '[data-theme="dark"]'
    assert_includes source, '[data-theme="light"]'
    refute_includes source, "--_nk-"
  end
end
