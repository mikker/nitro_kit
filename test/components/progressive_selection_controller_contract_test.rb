require "test_helper"

class ProgressiveSelectionControllerContractTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root.join("app/javascript/controllers/nk")

  test "tabs hide panels only while the controller is enhanced" do
    source = ROOT.join("tabs_controller.js").read

    assert_includes source, 'this.element.dataset.enhanced = "true"'
    assert_includes source, "if (!this.enhanced) return"
    assert_includes source, "panel.hidden = !active"
    assert_includes source, "panel.hidden = false"
    assert_includes source, 'panel.removeAttribute("aria-hidden")'
    assert_includes source, "panelTargetConnected()"
    assert_includes source, "tabTargetConnected()"
  end

  test "combobox swaps between one native submission control and its enhanced UI" do
    source = ROOT.join("combobox_controller.js").read

    assert_includes source, "this.controlTarget.hidden = false"
    assert_includes source, "this.nativeTarget.hidden = true"
    assert_includes source, "this.valueTarget.required = false"
    assert_includes source, "if (control) control.hidden = true"
    assert_includes source, "if (native) native.hidden = false"
    assert_includes source, "if (value) value.required = this.nativeRequired"
    assert_includes source, "delete this.element.dataset.enhanced"
    assert_includes source, "nativeTargetConnected(native)"
    assert_includes source, "valueTargetConnected(value)"
    assert_includes source, "controlTargetConnected(control)"
    assert_includes source, 'this.statusTarget.textContent = "No options found."'
    assert_includes source, 'count === 1 ? "option" : "options"'
    assert_includes source, '} available.`'
  end
end
