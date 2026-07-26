import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["image", "fallback"];

  imageTargetConnected(image) {
    if (image.complete && image.naturalWidth === 0) this.failed();
  }

  failed() {
    this.element.dataset.state = "error";
    if (this.hasFallbackTarget)
      this.fallbackTarget.removeAttribute("aria-hidden");
  }
}
