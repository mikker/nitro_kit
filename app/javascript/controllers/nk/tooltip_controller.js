import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  disconnect() {
    this.reset();
  }

  dismiss(event) {
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
}
