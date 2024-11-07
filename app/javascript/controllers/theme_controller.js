import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  connect() {
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", this.systemChanged.bind(this));
    this.setTheme(this.userPreference || this.system);
  }

  get system() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  get userPreference() {
    return localStorage.getItem("theme");
  }

  toggle(event) {
    // Prevent the toggle from toggling itself as we do it in setTheme
    event.stopPropagation();

    const theme =
      document.documentElement.dataset.theme === "dark" ? "light" : "dark";

    localStorage.setItem("theme", theme);

    this.setTheme(theme);
  }

  systemChanged() {
    if (this.userPreference) return;
    this.setTheme(this.system);
  }

  setTheme(theme) {
    document.documentElement.dataset.theme = theme;

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-checked", theme === "dark");
    }
  }
}
