import { Controller } from "@hotwired/stimulus";

const preferences = ["light", "dark", "system"];

export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.synchronize();
  }

  inputTargetConnected() {
    this.synchronize();
  }

  select(event) {
    const input = event.target;

    if (!this.inputTargets.includes(input)) return;
    if (input.type === "radio" && !input.checked) return;

    window.dispatchEvent(
      new CustomEvent("nitro-kit:appearance-request", {
        detail: { preference: input.value },
      }),
    );
  }

  synchronize(event) {
    const preference =
      event?.detail?.preference ??
      document.documentElement.dataset.themePreference ??
      "system";

    if (!preferences.includes(preference)) return;

    this.element.dataset.state = preference;
    this.inputTargets.forEach((input) => {
      if (input.type === "radio") {
        input.checked = input.value === preference;
      } else {
        input.value = preference;
      }
    });
  }
}
