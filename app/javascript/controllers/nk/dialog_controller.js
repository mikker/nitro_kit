import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog"];

  open() {
    if (this.dialogTarget.open) return;

    this.dialogTarget.showModal();
    this.dialogTarget.dataset.state = "open";
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close();
    this.syncClosed();
  }

  syncClosed() {
    this.dialogTarget.dataset.state = "closed";
  }

  clickOutside(event) {
    if (event.target !== this.dialogTarget) return;

    const rect = this.dialogTarget.getBoundingClientRect();
    const outside =
      event.clientX < rect.left ||
      event.clientX > rect.right ||
      event.clientY < rect.top ||
      event.clientY > rect.bottom;

    if (outside) this.close();
  }
}
