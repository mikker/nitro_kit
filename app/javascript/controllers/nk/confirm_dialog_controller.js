import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["message", "panel"];

  connect() {
    this.element.dataset.nkConfirmReady = "true";
    document.dispatchEvent(new CustomEvent("nitro-kit:confirm-ready"));
  }

  disconnect() {
    delete this.element.dataset.nkConfirmReady;
    this.resolve(false);
  }

  open(event) {
    event.preventDefault();

    this.resolve(false);
    this.resolver = event.detail.resolve;
    this.accepted = false;
    this.messageTarget.textContent = event.detail.message;

    if (!this.panelTarget.open) this.panelTarget.showModal();
  }

  accept() {
    this.accepted = true;
    this.panelTarget.close();
  }

  cancel() {
    this.accepted = false;
    this.panelTarget.close();
  }

  close() {
    this.resolve(this.accepted);
  }

  resolve(value) {
    this.resolver?.(value);
    this.resolver = null;
  }
}
