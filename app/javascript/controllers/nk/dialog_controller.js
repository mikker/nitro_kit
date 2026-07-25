import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel"];
  static values = { dismissible: Boolean };

  dismiss(event) {
    if (!this.dismissibleValue || event.target !== this.panelTarget) return;

    const rect = this.panelTarget.getBoundingClientRect();
    const inside =
      event.clientX >= rect.left &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom;

    if (!inside) this.panelTarget.close();
  }

  cancel(event) {
    if (!this.dismissibleValue) event.preventDefault();
  }
}
