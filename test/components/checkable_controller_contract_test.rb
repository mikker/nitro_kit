require "test_helper"

class CheckableControllerContractTest < ActiveSupport::TestCase
  SOURCE = NitroKit::Engine.root.join(
    "app/javascript/controllers/nk/checkable_controller.js"
  ).read

  test "applies the native indeterminate property and reflects it back" do
    assert_includes SOURCE, "this.controlTarget.indeterminate = this.indeterminateValue"
    assert_includes SOURCE, "change()"
    assert_includes SOURCE, "this.indeterminateValue = this.controlTarget.indeterminate"
    assert_includes SOURCE, "controlTargetConnected()"
    assert_includes SOURCE, "indeterminateValueChanged(indeterminate)"
    refute_includes SOURCE, "classList"
    refute_includes SOURCE, "addEventListener"
  end

  test "mirrors only the state HTML cannot express" do
    assert_includes SOURCE, 'this.element.dataset.state = "indeterminate"'
    assert_includes SOURCE, "delete this.element.dataset.state"
    refute_includes SOURCE, "aria-checked"
    refute_includes SOURCE, "synchronizeRadioGroup"
    refute_includes SOURCE, "getElementsByName"
    refute_includes SOURCE, '"checked"'
  end
end
