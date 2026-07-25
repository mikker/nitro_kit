import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static values = {
    active: String,
    activation: { type: String, default: "automatic" },
    orientation: { type: String, default: "horizontal" },
  };

  connect() {
    this.enhanced = true;
    this.element.dataset.enhanced = "true";
    this.synchronize();
  }

  disconnect() {
    this.enhanced = false;
    this.reconcileScheduled = false;
    delete this.element.dataset.enhanced;

    this.element
      .querySelectorAll(':scope > [data-slot="tabs-panel"]')
      .forEach((panel) => {
        panel.hidden = false;
        panel.removeAttribute("aria-hidden");
        panel.removeAttribute("tabindex");
      });

    this.element
      .querySelectorAll(
        ':scope > [data-slot="tabs-list"] > [data-slot="tabs-tab"]',
      )
      .forEach((tab) => {
        tab.tabIndex = tab.disabled ? -1 : 0;
      });
  }

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
    if (!this.enhanced) return;

    this.synchronize();
  }

  panelTargetConnected() {
    if (this.enhanced) this.synchronize();
  }

  panelTargetDisconnected() {
    this.scheduleReconciliation();
  }

  tabTargetConnected() {
    if (this.enhanced) this.synchronize();
  }

  tabTargetDisconnected() {
    this.scheduleReconciliation();
  }

  scheduleReconciliation() {
    if (!this.enhanced || this.reconcileScheduled) return;

    this.reconcileScheduled = true;
    queueMicrotask(() => {
      this.reconcileScheduled = false;
      if (this.enhanced) this.reconcileTargets();
    });
  }

  reconcileTargets() {
    const active = this.activeValue;
    const hasActivePair =
      this.tabTargets.some((tab) => tab.dataset.key === active) &&
      this.panelTargets.some((panel) => panel.dataset.key === active);

    if (!hasActivePair) {
      const fallback = this.tabTargets.find(
        (tab) =>
          !tab.disabled &&
          this.panelTargets.some(
            (panel) => panel.dataset.key === tab.dataset.key,
          ),
      );
      if (fallback) this.activeValue = fallback.dataset.key;
    }

    this.synchronize();
  }

  synchronize() {
    const value = this.activeValue;

    this.panelTargets.forEach((panel) => {
      const active = panel.dataset.key === value;

      panel.hidden = !active;
      panel.setAttribute("aria-hidden", String(!active));
      panel.dataset.state = active ? "active" : "inactive";
      panel.tabIndex = active ? 0 : -1;
    });

    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.key === value;

      tab.setAttribute("aria-selected", String(active));
      tab.dataset.state = active ? "active" : "inactive";
      tab.tabIndex = active && !tab.disabled ? 0 : -1;
    });
  }
}
