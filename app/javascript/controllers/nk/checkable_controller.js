import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["control"];
  static values = { indeterminate: Boolean };

  connect() {
    this.controlTarget.indeterminate = this.indeterminateValue;
    this.synchronize();
  }

  change() {
    this.indeterminateValue = this.controlTarget.indeterminate;

    if (this.controlTarget.type === "radio") {
      this.synchronizeRadioGroup();
    } else {
      this.synchronize();
    }
  }

  indeterminateValueChanged(indeterminate) {
    if (!this.hasControlTarget) return;

    this.controlTarget.indeterminate = indeterminate;
    this.synchronize();
  }

  controlTargetConnected(control) {
    control.indeterminate = this.indeterminateValue;
    this.synchronize();
  }

  synchronizeRadioGroup() {
    const control = this.controlTarget;

    if (!control.name) {
      this.synchronize();
      return;
    }

    document.getElementsByName(control.name).forEach((candidate) => {
      if (candidate.type !== "radio" || candidate.form !== control.form) return;

      const root = candidate.closest('[data-nk="radio-button"]');
      if (root)
        root.dataset.state = candidate.checked ? "checked" : "unchecked";
    });
  }

  synchronize() {
    const control = this.controlTarget;
    const state = control.indeterminate
      ? "indeterminate"
      : control.checked
        ? "checked"
        : "unchecked";

    this.element.dataset.state = state;

    if (control.indeterminate) {
      control.setAttribute("aria-checked", "mixed");
    } else {
      control.removeAttribute("aria-checked");
    }
  }
}
