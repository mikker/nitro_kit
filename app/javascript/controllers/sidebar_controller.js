import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["navigation", "toggle", "backdrop"];
  static values = { open: Boolean };

  connect() {
    // Set initial ARIA states
    this.navigationTarget.setAttribute("aria-hidden", !this.openValue);
    this.navigationTarget.setAttribute("aria-expanded", this.openValue);
  }

  open() {
    this.openValue = true;
  }

  close() {
    this.openValue = false;
  }

  toggle() {
    if (this.openValue) {
      this.close();
    } else {
      this.open();
    }
  }

  openValueChanged() {
    if (this.openValue) {
      this.navigationTarget.classList.remove("-translate-x-64");
      this.navigationTarget.setAttribute("aria-hidden", "false");
      this.navigationTarget.setAttribute("aria-expanded", "true");
      this.backdropTarget.classList.remove("opacity-0");
      document.addEventListener("click", this.handleClickOutside);
    } else {
      this.navigationTarget.classList.add("-translate-x-64");
      this.navigationTarget.setAttribute("aria-hidden", "true");
      this.navigationTarget.setAttribute("aria-expanded", "false");
      document.removeEventListener("click", this.handleClickOutside);
      this.backdropTarget.classList.add("opacity-0");
    }
  }

  handleClickOutside = (event) => {
    // Don't close if clicking inside the sidebar or on the menu button
    if (
      this.navigationTarget.contains(event.target) ||
      event.target.closest('[data-action="sidebar#open"]')
    )
      return;

    this.close();
  };
}
