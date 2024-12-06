import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
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

  set({ params }) {
    console.log(params);

    if (params.value === "system") {
      localStorage.removeItem("theme");
    } else {
      localStorage.setItem("theme", params.value);
    }

    this.setTheme(params.value);
  }

  systemChanged() {
    if (this.userPreference) return;
    this.setTheme(this.system);
  }

  setTheme(theme) {
    if (theme === "system") {
      document.documentElement.dataset.theme = this.system;
    } else {
      document.documentElement.dataset.theme = theme;
    }
  }
}
