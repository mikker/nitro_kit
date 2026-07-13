import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "content", "item"];

  disconnect() {
    this.close();
  }

  sync(event) {
    this.setState(event.newState === "open");
  }

  openFromKeyboard(event) {
    if (!["ArrowDown", "ArrowUp"].includes(event.key)) return;

    event.preventDefault();
    this.open();

    const items = this.enabledItems;
    const item = event.key === "ArrowUp" ? items.at(-1) : items[0];
    item?.focus();
  }

  navigate(event) {
    const items = this.enabledItems;
    if (items.length === 0) return;

    const currentIndex = items.indexOf(document.activeElement);
    let nextIndex;

    switch (event.key) {
      case "ArrowDown":
        nextIndex = (currentIndex + 1) % items.length;
        break;
      case "ArrowUp":
        nextIndex = (currentIndex - 1 + items.length) % items.length;
        break;
      case "Home":
        nextIndex = 0;
        break;
      case "End":
        nextIndex = items.length - 1;
        break;
      case "Escape":
        event.preventDefault();
        this.close();
        this.triggerTarget.focus();
        return;
      case "Tab":
        this.close();
        return;
      default:
        return;
    }

    event.preventDefault();
    items[nextIndex].focus();
  }

  select() {
    this.close();
  }

  open() {
    if (this.triggerTarget.disabled) return;

    if (typeof this.contentTarget.showPopover === "function") {
      if (!this.contentTarget.matches(":popover-open")) {
        this.contentTarget.showPopover();
      }
    }

    this.setState(true);
  }

  close() {
    if (!this.hasContentTarget) return;

    if (
      typeof this.contentTarget.hidePopover === "function" &&
      this.contentTarget.matches(":popover-open")
    ) {
      this.contentTarget.hidePopover();
    }

    this.setState(false);
  }

  setState(open) {
    const state = open ? "open" : "closed";
    this.element.dataset.state = state;
    if (this.hasContentTarget) this.contentTarget.dataset.state = state;
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(open));
    }
  }

  get enabledItems() {
    return this.itemTargets.filter(
      (item) => !item.disabled && item.getAttribute("aria-disabled") !== "true",
    );
  }
}
