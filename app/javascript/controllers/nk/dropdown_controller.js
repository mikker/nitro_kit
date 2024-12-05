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
  static values = {
    placement: { type: String, default: "bottom" },
  };

  connect() {
    this.updatePosition();
  }

  disconnect() {
    this.close();
  }

  get isExpanded() {
    return this.triggerTarget.getAttribute("aria-expanded") === "true";
  }

  updatePosition = () => {
    computePosition(this.triggerTarget, this.contentTarget, {
      placement: this.placementValue,
      middleware: [offset(5), flip(), shift({ padding: 5 })],
    }).then(({ x, y }) => {
      this.contentTarget.style.left = `${x}px`;
      this.contentTarget.style.top = `${y}px`;
    });
  };

  open = () => {
    this.triggerTarget.setAttribute("aria-expanded", "true");
    this.contentTarget.setAttribute("aria-hidden", "false");

    document.addEventListener("click", this.clickOutside);

    this.clearAutoUpdate = autoUpdate(
      this.triggerTarget,
      this.contentTarget,
      this.updatePosition,
    );
  };

  close = () => {
    this.triggerTarget.setAttribute("aria-expanded", "false");
    this.contentTarget.setAttribute("aria-hidden", "true");

    document.removeEventListener("click", this.clickOutside);

    if (this.clearAutoUpdate) {
      this.clearAutoUpdate();
    }
  };

  toggle = () => {
    if (this.isExpanded) {
      this.close();
    } else {
      this.open();
    }
  };

  clickOutside = (event) => {
    if (
      !this.contentTarget.contains(event.target) &&
      !this.triggerTarget.contains(event.target)
    ) {
      this.close();
    }
  };
}
