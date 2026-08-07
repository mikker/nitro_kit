require "test_helper"

class InteractionControllerContractTest < ActiveSupport::TestCase
  CONTROLLER_ROOT = NitroKit::Engine.root.join("app/javascript/controllers/nk")

  test "interaction controllers use only packaged browser positioning" do
    sources = %w[dropdown tooltip combobox command_palette toast].to_h do |name|
      [ name, CONTROLLER_ROOT.join("#{name}_controller.js").read ]
    end

    sources.each do |name, source|
      refute_includes source, "@floating-ui"
      refute_includes source, "@github/combobox-nav"
      next if %w[dropdown combobox].include?(name)

      refute_includes source, "addEventListener"
      refute_includes source, "MutationObserver"
      refute_includes source, "requestAnimationFrame"
    end

    assert_includes sources.fetch("dropdown"), "showPopover"
    assert_includes sources.fetch("dropdown"), "hidePopover"
    assert_includes sources.fetch("dropdown"), "pointerdown"
    assert_includes sources.fetch("dropdown"), "composedPath"
    refute_includes sources.fetch("dropdown"), "aria-expanded"
    refute_includes sources.fetch("dropdown"), "dataset.state"
    assert_includes sources.fetch("combobox"), "setCustomValidity"
    assert_includes sources.fetch("combobox"), "pointerdown"
    refute_includes sources.fetch("combobox"), 'removeAttribute("role")'
    refute_includes sources.fetch("combobox"), "TODO(i18n)"
    assert_includes sources.fetch("combobox"), "INVALID_SELECTION_MESSAGE"
    assert_includes sources.fetch("combobox"), "this.invalidSelectionValue ||"
    assert_includes sources.fetch("combobox"), "this.noResultsValue ||"
    assert_includes sources.fetch("combobox"), "this.resultsOneValue ||"
    assert_includes sources.fetch("combobox"), "this.resultsOtherValue ||"
    assert_includes sources.fetch("combobox"), "setSubmittedValue(value)"
    refute CONTROLLER_ROOT.join("accordion_controller.js").exist?
    assert CONTROLLER_ROOT.join("dialog_controller.js").exist?
    positioning = CONTROLLER_ROOT.join("overlay_position.js").read
    assert_includes positioning, 'document.addEventListener("scroll", callback, true)'
    assert_includes positioning, 'document.removeEventListener("scroll", callback, true)'
    refute NitroKit::Engine.root.join("app/components/nitro_kit/datepicker.rb").exist?
  end

  test "stateful controllers expose reconnect cleanup for every retained resource" do
    appearance = CONTROLLER_ROOT.join("appearance_controller.js").read
    tooltip = CONTROLLER_ROOT.join("tooltip_controller.js").read
    combobox = CONTROLLER_ROOT.join("combobox_controller.js").read
    command_palette = CONTROLLER_ROOT.join("command_palette_controller.js").read
    tabs = CONTROLLER_ROOT.join("tabs_controller.js").read
    toast = CONTROLLER_ROOT.join("toast_controller.js").read

    assert_includes appearance, "inputTargetConnected()"
    assert_includes tooltip, "disconnect()"
    assert_includes tooltip, "delete this.element.dataset.dismissed"
    refute_includes tooltip, "openValue"
    assert_includes combobox, "disconnect()"
    assert_includes combobox, "this.openValue = false"
    assert_includes combobox, "inputTargetDisconnected()"
    assert_includes combobox, "listboxTargetConnected()"
    assert_includes combobox, "optionTargetDisconnected(option)"
    assert_includes combobox, "reflectOpenState"
    assert_includes command_palette, "disconnect()"
    assert_includes command_palette, ':scope > [data-slot="command-palette-panel"]'
    assert_includes command_palette, "destinationTargetConnected()"
    assert_includes command_palette, "destinationTargetDisconnected()"
    assert_includes command_palette, "delete this.element.dataset.enhanced"

    assert_includes tabs, "panelTargetDisconnected()"
    assert_includes tabs, "tabTargetDisconnected()"
    assert_includes tabs, "reconcileTargets()"
    assert_includes tabs, "this.activeValue = fallback.dataset.key"

    assert_includes toast, "itemTargetConnected"
    assert_includes toast, "itemTargetDisconnected"
    assert_includes toast, "window.clearTimeout"
    assert_includes toast, "this.timers?.clear()"
    assert_includes toast, "pause(event)"
    assert_includes toast, "resume(event)"
    assert_includes toast, "teardown()"
    assert_includes toast, 'item.dataset.state === "closed"'
    assert_includes toast, 'item.matches(":hover, :focus-within")'
    assert_includes toast, "getComputedStyle(item)"
  end
end
