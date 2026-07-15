require "test_helper"

class CheckableControllerContractTest < ActiveSupport::TestCase
  SOURCE = NitroKit::Engine.root.join(
    "app/javascript/controllers/nk/checkable_controller.js"
  ).read

  test "sets native indeterminate state and reflects native changes" do
    assert_includes SOURCE, "this.controlTarget.indeterminate = this.indeterminateValue"
    assert_includes SOURCE, "change()"
    assert_includes SOURCE, "this.element.dataset.state = state"
    assert_includes SOURCE, 'control.setAttribute("aria-checked", "mixed")'
    assert_includes SOURCE, 'control.removeAttribute("aria-checked")'
    refute_includes SOURCE, "classList"
  end

  test "updates same-form radio peers and reconnects replaced controls" do
    assert_includes SOURCE, "document.getElementsByName(control.name)"
    assert_includes SOURCE, "candidate.form !== control.form"
    assert_includes SOURCE, "controlTargetConnected(control)"
    assert_includes SOURCE, "indeterminateValueChanged(indeterminate)"
    refute_includes SOURCE, "addEventListener"
  end
end
