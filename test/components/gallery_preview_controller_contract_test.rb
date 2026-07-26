require "test_helper"

class GalleryPreviewControllerContractTest < ActiveSupport::TestCase
  # Resize behavior itself is covered by test/system/gallery_responsive_preview_test.rb.
  # This contract only guards the resources the controller may retain.
  test "controller owns only ephemeral viewport state and cleans observers and pointer capture" do
    source = File.read(Rails.root.join("app/javascript/controllers/gallery/preview_controller.js"))

    assert_includes source, "ResizeObserver"
    assert_includes source, "disconnect()"
    assert_includes source, "setPointerCapture"
    assert_includes source, "releasePointerCapture"
    refute_includes source, "localStorage"
    refute_includes source, "document.addEventListener"
    refute_includes source, "window.addEventListener"
  end
end
