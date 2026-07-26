require "test_helper"

# Drawer behavior, focus, morph reconciliation, and disconnect are exercised in
# test/system/app_shell_test.rb. This contract only guards the choices that are
# invisible from the outside: native modality instead of a hand-rolled focus
# trap, one moved navigation tree instead of a copy, and live Stimulus targets
# instead of cached element references.
class AppShellControllerContractTest < ActiveSupport::TestCase
  CONTROLLER = NitroKit::Engine.root.join("app/javascript/controllers/nk/app_shell_controller.js")

  test "delegates narrow modality to the native dialog" do
    source = CONTROLLER.read

    assert_includes source, "showModal()"
    assert_includes source, 'matches(":modal")'
    refute_includes source, "trapFocus"
    refute_includes source, "focusableSelector"
    refute_includes source, ".inert ="
    refute_includes source, 'document.addEventListener("pointerdown"'
    refute_includes source, 'document.body.style.overflow = "hidden"'
    refute_includes source, "requestAnimationFrame"
  end

  test "moves one navigation tree between the sidebar and dialog" do
    source = CONTROLLER.read

    assert_includes source, '"(max-width: 48rem)"'
    assert_includes source, "window.matchMedia"
    assert_includes source, "container.append(this.navigationTarget)"
    refute_includes source, "cloneNode"
    refute_includes source, "innerHTML"
  end

  test "uses live targets across morphs and pairs the retained listener" do
    source = CONTROLLER.read

    assert_includes source, 'static targets = ["dialog", "navigation", "sidebar", "trigger"]'
    assert_includes source, "dialogTargetConnected()"
    assert_includes source, "dialogTargetDisconnected(dialog)"
    assert_includes source, "navigationTargetConnected()"
    assert_includes source, "sidebarTargetConnected()"
    assert_includes source, "triggerTargetConnected(trigger)"
    assert_includes source, 'addEventListener("change", this.onViewportChange)'
    assert_includes source, 'removeEventListener("change", this.onViewportChange)'
    refute_includes source, "this.dialogElement ="
    refute_includes source, "this.navigationElement ="
    refute_includes source, "this.sidebarElement ="
    refute_includes source, "this.triggerElement ="
  end

  test "re-asserts the enhancement marker every time the shell reconciles" do
    source = CONTROLLER.read
    component = NitroKit::Engine.root.join("app/components/nitro_kit/app_shell.rb").read

    assert_includes source, 'this.element.dataset.enhanced = ""'
    assert_includes source, "delete this.element.dataset.enhanced"
    assert_includes source[/syncViewport\(\) \{.*?\n  \}/m].to_s, 'this.element.dataset.enhanced = ""'
    assert_includes component, "turbo:morph@document->nk--app-shell#syncViewport"
  end
end
