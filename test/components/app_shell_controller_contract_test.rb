require "test_helper"

class AppShellControllerContractTest < ActiveSupport::TestCase
  CONTROLLER = NitroKit::Engine.root.join("app/javascript/controllers/nk/app_shell_controller.js")

  test "delegates narrow modality to the native dialog" do
    source = CONTROLLER.read

    assert_includes source, "this.dialogTarget.showModal()"
    assert_includes source, "this.dialogTarget.close()"
    assert_includes source, 'this.dialogTarget.matches(":modal")'
    assert_includes source, "closeFromBackdrop(event)"
    assert_includes source, "dialogClosed()"
    refute_includes source, "trapFocus"
    refute_includes source, "focusableSelector"
    refute_includes source, ".inert ="
    refute_includes source, 'document.addEventListener("pointerdown"'
    refute_includes source, 'document.body.style.overflow = "hidden"'
    refute_includes source, "requestAnimationFrame"
  end

  test "moves one navigation tree between the sidebar and dialog" do
    source = CONTROLLER.read

    assert_includes source, 'const narrowViewport = "(max-width: 48rem)"'
    assert_includes source, "window.matchMedia(narrowViewport)"
    assert_includes source, 'this.element.dataset.enhanced = ""'
    assert_includes source, "delete this.element.dataset.enhanced"
    assert_includes source, "this.moveNavigationTo(this.dialogTarget)"
    assert_includes source, "this.moveNavigationTo(this.sidebarTarget)"
    assert_includes source, "container.append(this.navigationTarget)"
    assert_includes source, 'this.element.dataset.state = open ? "open" : "closed"'
    assert_includes source, 'trigger.setAttribute("aria-expanded", String(open))'
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
    assert_includes source, "this.previouslyFocused?.isConnected"
    refute_includes source, "this.dialogElement ="
    refute_includes source, "this.navigationElement ="
    refute_includes source, "this.sidebarElement ="
    refute_includes source, "this.triggerElement ="
  end
end
