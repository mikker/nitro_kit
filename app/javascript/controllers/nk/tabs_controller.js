import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static values = { active: String };

  setActiveTab(event) {
    this.activeValue = event.params.key;
  }

  prevTab(event) {
    const prevTab = event.target.previousElementSibling;
    if (prevTab) {
      prevTab.click();
      prevTab.focus();
    }
  }

  nextTab(event) {
    const nextTab = event.target.nextElementSibling;
    if (nextTab) {
      nextTab.click();
      nextTab.focus();
    }
  }

  activeValueChanged() {
    const value = this.activeValue;

    this.panelTargets.forEach((panel) => {
      if (panel.dataset.key === value) {
        panel.ariaHidden = false;
      } else {
        panel.ariaHidden = true;
      }
    });

    this.tabTargets.forEach((tab) => {
      if (tab.dataset.key === value) {
        tab.ariaSelected = true;
      } else {
        tab.ariaSelected = false;
      }
    });
  }
}
