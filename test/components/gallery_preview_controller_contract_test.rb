require "test_helper"

class GalleryPreviewControllerContractTest < ActiveSupport::TestCase
  test "controller owns only ephemeral viewport state and cleans observers and pointer capture" do
    source = File.read(Rails.root.join("app/javascript/controllers/gallery/preview_controller.js"))

    assert_includes source, "new ResizeObserver"
    assert_includes source, "new previewWindow.ResizeObserver"
    assert_includes source, "this.trackObserver?.disconnect()"
    assert_includes source, "this.documentObserver?.disconnect()"
    assert_includes source, "this.handleTarget.setPointerCapture(event.pointerId)"
    assert_includes source, "this.handleTarget.releasePointerCapture(this.pointerId)"
    assert_includes source, "ArrowLeft"
    assert_includes source, "ArrowRight"
    assert_includes source, "Home"
    assert_includes source, "End"
    assert_includes source, 'this.element.style.setProperty("--gallery-preview-width"'
    refute_includes source, "localStorage"
    refute_includes source, "document.addEventListener"
    refute_includes source, "window.addEventListener"
  end
end
