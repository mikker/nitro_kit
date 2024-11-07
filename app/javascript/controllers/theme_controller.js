import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static mountAs = "theme";

  connect() {
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", this.updateThemeFromSystem.bind(this));

    // Check localStorage first, fallback to system preference
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme) {
      this.setTheme(savedTheme);
    } else {
      this.setTheme(this.systemIsDark() ? "dark" : "light");
    }
  }

  systemIsDark() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  toggle() {
    const isDark = document.documentElement.classList.contains("dark");
    this.setTheme(isDark ? "light" : "dark");
  }

  setTheme(theme) {
    localStorage.setItem("theme", theme);

    if (theme === "dark") {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }
}
