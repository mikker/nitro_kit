import { Controller } from "@hotwired/stimulus";
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "@floating-ui/dom";

export default class extends Controller {
  static targets = ["content"];
  static values = {
    open: { type: Boolean, default: false },
    // Options for floating-ui
    placement: { type: String, default: "top" },
  };

  connect() {
    this.updatePosition();
  }

  disconnect() {
    this.close();
  }

  open() {
    this.openValue = true;
  }

  close() {
    this.openValue = false;
  }

  openValueChanged(state, _previous) {
    this.contentTarget.dataset.state = state ? "open" : "closed";

    if (state) {
      this.clearAutoUpdate = autoUpdate(
        this.element,
        this.contentTarget,
        this.updatePosition,
      );
    } else {
      if (this.clearAutoUpdate) {
        this.clearAutoUpdate();
      }
    }
  }

  updatePosition = () => {
    computePosition(this.element, this.contentTarget, {
      placement: this.placementValue,
      middleware: [offset(5), flip(), shift({ padding: 5 })],
    }).then(({ x, y }) => {
      this.contentTarget.style.left = `${x}px`;
      this.contentTarget.style.top = `${y}px`;
    });
  };
}
