import { Controller } from "@hotwired/stimulus";
import {
  observeOverlayPosition,
  positionOverlay,
} from "controllers/nk/overlay_position";

export default class extends Controller {
  static targets = ["trigger", "content", "item"];

  disconnect() {
    this.stopPositioning?.();
  }

  openFromKeyboard(event) {
    if (!["ArrowDown", "ArrowUp"].includes(event.key)) return;
    if (this.triggerTarget.disabled) return;

    event.preventDefault();
    this.focusLast = event.key === "ArrowUp";

    if (this.contentTarget.matches(":popover-open")) {
      this.focusInitialItem();
    } else {
      this.contentTarget.showPopover();
    }
  }

  rememberFocus(event) {
    if (event.newState === "open") return;

    this.hadFocus =
      this.restoreOnClose !== false &&
      this.contentTarget.contains(document.activeElement);
  }

  focusOpened(event) {
    if (event.newState === "open") {
      this.startPositioning();
      this.focusInitialItem();
    } else {
      this.stopPositioning?.();
      this.stopPositioning = null;
      this.focusLast = false;
      this.restoreFocus();
    }
  }

  restoreFocus() {
    if (!this.hadFocus) return;

    this.hadFocus = false;
    this.triggerTarget.focus();
  }

  startPositioning() {
    this.stopPositioning?.();
    const update = () =>
      positionOverlay(
        this.triggerTarget,
        this.contentTarget,
        this.element.dataset.placement,
      );

    update();
    this.stopPositioning = observeOverlayPosition(update);
  }

  navigate(event) {
    switch (event.key) {
      case "Escape":
        event.preventDefault();
        this.hide();
        return;
      case "Tab":
        this.hide({ restoreFocus: false });
        return;
    }

    const items = this.enabledItems;
    if (items.length === 0) return;

    const currentIndex = items.indexOf(document.activeElement);
    const nextIndex = {
      ArrowDown: (currentIndex + 1) % items.length,
      ArrowUp: (currentIndex - 1 + items.length) % items.length,
      Home: 0,
      End: items.length - 1,
    }[event.key];

    if (nextIndex === undefined) return;

    event.preventDefault();
    items[nextIndex].focus();
  }

  select() {
    this.hide();
  }

  focusInitialItem() {
    const item = this.focusLast
      ? this.enabledItems.at(-1)
      : this.enabledItems[0];

    this.focusLast = false;
    if (item) {
      item.focus();
    } else {
      this.contentTarget.focus();
    }
  }

  hide({ restoreFocus = true } = {}) {
    this.restoreOnClose = restoreFocus;
    if (this.contentTarget.matches(":popover-open")) {
      this.contentTarget.hidePopover();
    }
    this.restoreOnClose = true;
  }

  get enabledItems() {
    return this.itemTargets.filter(
      (item) => !item.disabled && item.getAttribute("aria-disabled") !== "true",
    );
  }
}
