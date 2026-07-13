require "test_helper"

class InteractionControllerContractTest < ActiveSupport::TestCase
  CONTROLLER_ROOT = NitroKit::Engine.root.join("app/javascript/controllers/nk")

  test "interaction controllers no longer depend on positioning or combobox packages" do
    sources = %w[dropdown tooltip combobox toast].to_h do |name|
      [ name, CONTROLLER_ROOT.join("#{name}_controller.js").read ]
    end

    sources.each_value do |source|
      refute_includes source, "@floating-ui"
      refute_includes source, "@github/combobox-nav"
      refute_includes source, "addEventListener"
      refute_includes source, "MutationObserver"
      refute_includes source, "requestAnimationFrame"
    end

    assert_includes sources.fetch("dropdown"), "showPopover"
    assert_includes sources.fetch("dropdown"), "hidePopover"
    assert_includes sources.fetch("combobox"), "setCustomValidity"
    refute_includes sources.fetch("combobox"), 'removeAttribute("role")'
    refute NitroKit::Engine.root.join("app/javascript/controllers/nk/datepicker_controller.js").exist?
  end

  test "stateful controllers expose reconnect cleanup for every retained resource" do
    tooltip = CONTROLLER_ROOT.join("tooltip_controller.js").read
    combobox = CONTROLLER_ROOT.join("combobox_controller.js").read
    toast = CONTROLLER_ROOT.join("toast_controller.js").read

    assert_includes tooltip, "disconnect()"
    assert_includes tooltip, "this.openValue = false"
    assert_includes combobox, "disconnect()"
    assert_includes combobox, "this.openValue = false"

    assert_includes toast, "itemTargetConnected"
    assert_includes toast, "itemTargetDisconnected"
    assert_includes toast, "window.clearTimeout"
    assert_includes toast, "this.timers?.clear()"
    assert_includes toast, "pause(event)"
    assert_includes toast, "resume(event)"
  end
end
