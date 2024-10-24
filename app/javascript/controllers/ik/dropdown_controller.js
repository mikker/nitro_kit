import { Controller } from "@hotwired/stimulus";
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "@floating-ui/dom";

export default class extends Controller {
  static targets = ["trigger", "content"];
  static values = { open: { type: Boolean, default: false } };

  connect() {
    this.updatePosition();
  }

  disconnect() {
    this.close();
  }

  updatePosition = () => {
    computePosition(this.triggerTarget, this.contentTarget, {
      placement: "bottom-end",
      middleware: [offset(5), flip(), shift({ padding: 5 })],
    }).then(({ x, y }) => {
      this.contentTarget.style.left = `${x}px`;
      this.contentTarget.style.top = `${y}px`;
    });
  };

  open = () => {
    this.openValue = true;
  };

  close = () => {
    this.openValue = false;
  };

  toggle = () => {
    if (this.openValue) {
      this.close();
    } else {
      this.open();
    }
  };

  openValueChanged() {
    if (this.openValue) {
      this.contentTarget.classList.remove("hidden");

      document.addEventListener("click", this.clickOutside);

      this.clearAutoUpdate = autoUpdate(
        this.triggerTarget,
        this.contentTarget,
        this.updatePosition
      );
    } else {
      this.contentTarget.classList.add("hidden");

      document.removeEventListener("click", this.clickOutside);

      if (this.clearAutoUpdate) {
        this.clearAutoUpdate();
      }
    }
  }

  clickOutside = (event) => {
    if (
      !this.contentTarget.contains(event.target) &&
      !this.triggerTarget.contains(event.target)
    ) {
      this.close();
    }
  };
}
