import { Controller } from "@hotwired/stimulus";

const preferences = ["light", "dark", "system"];

export default class extends Controller {
  static targets = ["input", "trigger"];

  connect() {
    this.synchronize();
  }

  inputTargetConnected() {
    this.synchronize();
  }

  triggerTargetConnected() {
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
    this.updateTriggerGlyph(preference);
  }

  // The dropdown trigger renders the server-side preference glyph. Each menu
  // item already carries the glyph for its own preference, so a client-side
  // change swaps the trigger's drawing instructions instead of teaching this
  // controller what any appearance looks like.
  updateTriggerGlyph(preference) {
    if (!this.hasTriggerTarget) return;

    const glyph = this.triggerTarget.querySelector('[data-nk="icon"]');
    const source = this.inputTargets.find(
      (input) => input.dataset.appearancePreference === preference,
    );
    const replacement = source?.querySelector('[data-nk="icon"]');

    if (!glyph || !replacement || glyph === replacement) return;

    glyph.replaceChildren(...replacement.cloneNode(true).children);
  }
}
