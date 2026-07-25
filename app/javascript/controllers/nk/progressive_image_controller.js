import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["image", "fallback"];

  connect() {
    this.connected = true;
    this.onLoad ||= this.loaded.bind(this);
    this.onError ||= this.failed.bind(this);
    this.element.dataset.enhanced = "true";

    if (this.hasImageTarget) {
      this.bindImage(this.imageTarget);
    } else {
      this.setState("empty");
    }
  }

  disconnect() {
    this.connected = false;
    this.releaseImage();
    delete this.element.dataset.enhanced;

    if (this.hasFallbackTarget) this.fallbackTarget.hidden = true;
  }

  imageTargetConnected(image) {
    if (this.connected) this.bindImage(image);
  }

  imageTargetDisconnected(image) {
    if (this.boundImage !== image) return;

    this.releaseImage();
    if (this.connected && !this.hasImageTarget) this.setState("empty");
  }

  fallbackTargetConnected(fallback) {
    if (!this.connected) return;

    fallback.hidden = !["empty", "error"].includes(this.element.dataset.state);
  }

  bindImage(image) {
    if (this.boundImage === image) return;

    this.releaseImage();
    this.boundImage = image;
    this.revision = (this.revision || 0) + 1;
    this.setState("loading");
    image.addEventListener("load", this.onLoad);
    image.addEventListener("error", this.onError);

    if (image.complete) this.reflectComplete(image);
  }

  releaseImage() {
    if (this.boundImage) {
      this.boundImage.removeEventListener("load", this.onLoad);
      this.boundImage.removeEventListener("error", this.onError);
    }

    this.boundImage = null;
    this.revision = (this.revision || 0) + 1;
  }

  async loaded(event) {
    const image = event?.currentTarget || this.boundImage;
    if (!image || image !== this.boundImage) return;

    const revision = ++this.revision;

    if (typeof image.decode === "function") {
      try {
        await image.decode();
      } catch {
        // naturalWidth below remains the source of truth for cached and SVG images.
      }
    }

    if (
      !this.connected ||
      image !== this.boundImage ||
      revision !== this.revision
    ) {
      return;
    }

    this.setState(image.naturalWidth > 0 ? "loaded" : "error");
  }

  failed(event) {
    const image = event?.currentTarget || this.boundImage;
    if (!image || image !== this.boundImage) return;

    this.revision = (this.revision || 0) + 1;
    this.setState("error");
  }

  reflectComplete(image) {
    if (image.naturalWidth > 0) {
      this.loaded();
    } else {
      this.failed();
    }
  }

  setState(state) {
    this.element.dataset.state = state;
    this.element.setAttribute("aria-busy", String(state === "loading"));

    if (this.hasFallbackTarget) {
      this.fallbackTarget.hidden = !["empty", "error"].includes(state);
    }
  }
}
