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
    const input = this.inputTargets.find(
      (target) => target === event.target || target === event.currentTarget,
    );

    if (!input) return;
    if (input.type === "radio" && !input.checked) return;

    const preference = input.dataset.appearancePreference ?? input.value;

    window.dispatchEvent(
      new CustomEvent("nitro-kit:appearance-request", {
        detail: { preference },
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
      } else if (input.localName === "select") {
        input.value = preference;
      }
    });
  }
}
