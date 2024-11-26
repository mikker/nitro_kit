import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "dialog"];

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.close();
    }
  }
}
