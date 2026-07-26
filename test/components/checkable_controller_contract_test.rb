require "test_helper"

class CheckableControllerContractTest < ActiveSupport::TestCase
  SOURCE = NitroKit::Engine.root.join(
    "app/javascript/controllers/nk/checkable_controller.js"
  ).read

  test "drives the native indeterminate property in both directions" do
    assert_includes SOURCE, "controlTarget.indeterminate"
    assert_includes SOURCE, "controlTargetConnected()"
    assert_includes SOURCE, "indeterminateValueChanged"
    refute_includes SOURCE, "classList"
    refute_includes SOURCE, "addEventListener"
  end

  test "mirrors only the state HTML cannot express" do
    assert_includes SOURCE, "dataset.state"
    assert_includes SOURCE, '"indeterminate"'
    refute_includes SOURCE, "aria-checked"
    refute_includes SOURCE, "getElementsByName"
    refute_includes SOURCE, '"checked"'
  end
end
