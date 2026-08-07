import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  disconnect() {
    this.reset();
  }

  dismiss(event) {
    if (!this.shown) return;

    event.preventDefault();
    this.element.dataset.dismissed = "";
  }

  resetIfUninterested(event) {
    if (event.relatedTarget && this.element.contains(event.relatedTarget))
      return;
    if (this.element.matches(":hover, :focus-within")) return;

    this.reset();
  }

  reset() {
    delete this.element.dataset.dismissed;
  }

  get shown() {
    return (
      !("dismissed" in this.element.dataset) &&
      this.element.matches(":hover, :focus-within")
    );
  }
}
