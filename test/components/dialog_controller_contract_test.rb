require "test_helper"

class DialogControllerContractTest < ActiveSupport::TestCase
  CONTROLLER = NitroKit::Engine.root.join("app/javascript/controllers/nk/dialog_controller.js")

  test "keeps native invoker commands preferred and limits fallback to dialog methods" do
    source = CONTROLLER.read

    assert_includes source, "invoker.commandForElement === panel"
    assert_includes source, "invoker.command === command"
    assert_includes source, "panel.showModal()"
    assert_includes source, "panel.close()"
    assert_includes source, "event.preventDefault()"
    refute_includes source, "navigator.userAgent"
    refute_includes source, "MutationObserver"
    refute_includes source, "dataset.state"
  end

  test "delegates application commands and cleans an open panel before Turbo caches it" do
    source = CONTROLLER.read

    assert_includes source, '"[command], [data-nk--dialog-command]"'
    assert_includes source, 'invoker.getAttribute("commandfor")'
    assert_includes source, "closeForCache()"
    assert_includes source, "if (this.panelTarget.open) this.panelTarget.close()"
  end
end
