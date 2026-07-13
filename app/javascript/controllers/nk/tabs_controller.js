import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static values = {
    active: String,
    activation: { type: String, default: "automatic" },
    orientation: { type: String, default: "horizontal" },
  };

  select(event) {
    if (!event.currentTarget.disabled) {
      this.activeValue = event.currentTarget.dataset.key;
    }
  }

  navigate(event) {
    const directionKeys =
      this.orientationValue === "vertical"
        ? ["ArrowUp", "ArrowDown"]
        : ["ArrowLeft", "ArrowRight"];

    if (![...directionKeys, "Home", "End"].includes(event.key)) return;

    event.preventDefault();

    const enabledTabs = this.tabTargets.filter((tab) => !tab.disabled);
    const currentIndex = enabledTabs.indexOf(event.currentTarget);

    if (currentIndex === -1) return;

    let nextIndex;

    if (event.key === "Home") {
      nextIndex = 0;
    } else if (event.key === "End") {
      nextIndex = enabledTabs.length - 1;
    } else {
      const offset = event.key === directionKeys[0] ? -1 : 1;
      nextIndex =
        (currentIndex + offset + enabledTabs.length) % enabledTabs.length;
    }

    const nextTab = enabledTabs[nextIndex];

    if (this.activationValue === "automatic") {
      this.activeValue = nextTab.dataset.key;
    } else {
      this.tabTargets.forEach((tab) => {
        tab.tabIndex = -1;
      });
      nextTab.tabIndex = 0;
    }

    nextTab.focus();
  }

  activeValueChanged() {
    const value = this.activeValue;

    this.panelTargets.forEach((panel) => {
      const active = panel.dataset.key === value;

      panel.hidden = !active;
      panel.setAttribute("aria-hidden", String(!active));
      panel.dataset.state = active ? "active" : "inactive";
    });

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.key === value;

      tab.setAttribute("aria-selected", String(active));
      tab.dataset.state = active ? "active" : "inactive";
      tab.tabIndex = active && !tab.disabled ? 0 : -1;
    });
  }
}
