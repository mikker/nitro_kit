import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static mountAs = "theme";
  connect() {
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", this.updateTheme);
    this.updateTheme();
  }

  updateTheme() {
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }
}
