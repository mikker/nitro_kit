import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];
  static values = { open: Boolean };

  disconnect() {
    this.openValue = false;
    this.element.dataset.state = "closed";
    if (this.hasContentTarget) {
      this.contentTarget.dataset.state = "closed";
      this.contentTarget.hidden = true;
    }
  }

  open() {
    this.openValue = true;
  }

  close() {
    this.openValue = false;
  }

  openValueChanged(open) {
    const state = open ? "open" : "closed";
    this.element.dataset.state = state;
    this.contentTarget.dataset.state = state;
    this.contentTarget.hidden = !open;
  }
}
