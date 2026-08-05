require "test_helper"

class ProgressiveImageControllerContractTest < ActiveSupport::TestCase
  SOURCE = NitroKit::Engine.root.join(
    "app/javascript/controllers/nk/progressive_image_controller.js"
  ).read

  test "decodes images and reflects only closed data states" do
    assert_includes SOURCE, "image.decode()"
    assert_includes SOURCE, 'this.setState("empty")'
    assert_includes SOURCE, 'this.setState(image.naturalWidth > 0 ? "loaded" : "error")'
    assert_includes SOURCE, 'this.setState("error")'
    assert_includes SOURCE, "this.element.dataset.state = state"
    assert_includes SOURCE, 'this.element.dataset.enhanced = "true"'
    refute_includes SOURCE, 'this.imageTarget.setAttribute("aria-hidden", "true")'
    refute_includes SOURCE, 'this.imageTarget.removeAttribute("aria-hidden")'
    refute_includes SOURCE, "classList"
  end

  test "releases exact image listeners and invalidates pending decodes" do
    assert_includes SOURCE, "disconnect()"
    assert_includes SOURCE, 'image.addEventListener("load", this.onLoad)'
    assert_includes SOURCE, 'image.addEventListener("error", this.onError)'
    assert_includes SOURCE, 'this.boundImage.removeEventListener("load", this.onLoad)'
    assert_includes SOURCE, 'this.boundImage.removeEventListener("error", this.onError)'
    assert_includes SOURCE, "imageTargetConnected(image)"
    assert_includes SOURCE, "imageTargetDisconnected(image)"
    assert_includes SOURCE, "fallbackTargetConnected(fallback)"
    assert_includes SOURCE, 'this.setState("loading")'
    assert_includes SOURCE, 'this.setState("empty")'
    assert_includes SOURCE, "if (image.complete)"
    assert_includes SOURCE, 'this.setState(image.naturalWidth > 0 ? "loaded" : "error")'
    assert_includes SOURCE, "!this.hasImageTarget"
    assert_includes SOURCE, "revision !== this.revision"
    assert_includes SOURCE, "delete this.element.dataset.enhanced"
    assert_includes SOURCE, "prepareForCache()"
  end
end
