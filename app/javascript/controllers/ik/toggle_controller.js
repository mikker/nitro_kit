import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (!this.element.hasAttribute("tabindex")) {
      this.element.setAttribute("tabindex", "0");
    }
  }

  click() {
    if (this.element.hasAttribute("disabled")) return;

    this.toggle();
  }

  keydown(event) {
    if (this.element.hasAttribute("disabled")) return;

    if (event.code === "Space" || event.code === "Enter") {
      event.preventDefault();
      this.toggle();
    }
  }

  get checked() {
    return this.element.getAttribute("aria-checked") === "true";
  }

  toggle() {
    this.element.setAttribute("aria-checked", (!this.checked).toString());
  }
}
