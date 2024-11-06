import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["navigation"];

  open() {
    this.navigationTarget.classList.remove("-translate-x-64");
  }

  close() {
    this.navigationTarget.classList.add("-translate-x-64");
  }

  toggle() {
    this.navigationTarget.classList.toggle("-translate-x-64");
  }
}
