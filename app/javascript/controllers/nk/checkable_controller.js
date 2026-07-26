import { Controller } from "@hotwired/stimulus";

// Indeterminate is the only checkbox state HTML cannot express. Checked,
// unchecked, and radio selection stay native and are styled through :checked.
export default class extends Controller {
  static targets = ["control"];
  static values = { indeterminate: Boolean };

  connect() {
    this.apply();
  }

  change() {
    this.indeterminateValue = this.controlTarget.indeterminate;
    this.synchronize();
  }

  indeterminateValueChanged(indeterminate) {
    if (!this.hasControlTarget) return;

    this.controlTarget.indeterminate = indeterminate;
    this.synchronize();
  }

  controlTargetConnected() {
    this.apply();
  }

  apply() {
    this.controlTarget.indeterminate = this.indeterminateValue;
    this.synchronize();
  }

  synchronize() {
    if (this.controlTarget.indeterminate) {
      this.element.dataset.state = "indeterminate";
    } else {
      delete this.element.dataset.state;
    }
  }
}
