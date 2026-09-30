import { Controller } from "@hotwired/stimulus";

const narrowViewport = "(width < 48rem)";

export default class extends Controller {
  static targets = ["dialog", "navigation", "sidebar", "trigger", "pin"];
  static values = {
    openLabel: String,
    closeLabel: String,
    collapsible: { type: Boolean, default: false },
    pinned: { type: Boolean, default: true },
    hoverSuppressed: { type: Boolean, default: false },
  };

  connect() {
    this.onViewportChange = this.syncViewport.bind(this);
    this.viewport = window.matchMedia(narrowViewport);
    this.viewport.addEventListener("change", this.onViewportChange);
    this.syncViewport();
  }

  disconnect() {
    this.viewport?.removeEventListener("change", this.onViewportChange);
    this.hoverSuppressedValue = false;
    this.restoreFocusAfterClose = false;

    const dialog = this.element.querySelector(
      '[data-nk--app-shell-target~="dialog"]',
    );
    const sidebar = this.element.querySelector(
      '[data-nk--app-shell-target~="sidebar"]',
    );
    const navigation = this.element.querySelector(
      '[data-nk--app-shell-target~="navigation"]',
    );
    const trigger = this.element.querySelector(
      '[data-nk--app-shell-target~="trigger"]',
    );

    if (dialog?.open) dialog.close();
    if (sidebar && navigation && navigation.parentElement !== sidebar) {
      sidebar.append(navigation);
    }

    this.element.dataset.state = "closed";
    trigger?.setAttribute("aria-expanded", "false");
    trigger?.setAttribute("aria-label", this.openLabelValue);
    delete this.element.dataset.enhanced;

    this.previouslyFocused = null;
    this.viewport = null;
  }

  toggle(event) {
    event.preventDefault();
    this.dialogTarget.open ? this.closeDialog() : this.open();
  }

  togglePin(event) {
    if (
      !this.collapsibleValue ||
      this.isNarrow ||
      this.element.dataset.layout !== "sidebar"
    )
      return;

    this.hoverSuppressedValue = this.pinnedValue && event.detail > 0;
    this.pinnedValue = !this.pinnedValue;
  }

  resumeHover(event) {
    const brand = this.element.querySelector(
      ':scope > [data-slot="app-shell-header"] > [data-slot="app-shell-brand"]',
    );
    if (
      this.sidebarTarget.contains(event.relatedTarget) ||
      brand?.contains(event.relatedTarget)
    )
      return;

    this.hoverSuppressedValue = false;
  }

  pinnedValueChanged() {
    if (this.hasPinTarget)
      this.pinTarget.setAttribute("aria-pressed", String(this.pinnedValue));
  }

  pinTargetConnected(pin) {
    pin.setAttribute("aria-pressed", String(this.pinnedValue));
  }

  open() {
    if (!this.isNarrow || this.dialogTarget.open) return;

    this.previouslyFocused = document.activeElement;
    this.restoreFocusAfterClose = true;
    this.moveNavigationTo(this.dialogTarget);
    this.dialogTarget.showModal();
    this.setState(true);
  }

  close(event) {
    event?.preventDefault();
    this.closeDialog();
  }

  closeFromBackdrop(event) {
    if (event.target !== this.dialogTarget) return;

    const bounds = this.dialogTarget.getBoundingClientRect();
    const insideDialog =
      event.clientX >= bounds.left &&
      event.clientX <= bounds.right &&
      event.clientY >= bounds.top &&
      event.clientY <= bounds.bottom;

    if (!insideDialog) this.close(event);
  }

  closeForNavigation() {
    this.hoverSuppressedValue = false;
    this.closeDialog({ restoreFocus: false });
  }

  preserveSidebarState(event) {
    if (!this.collapsibleValue || this.element.dataset.layout !== "sidebar")
      return;

    const attribute = event.detail.attributeName;
    const sidebarState =
      event.target === this.element &&
      [
        "data-nk--app-shell-pinned-value",
        "data-nk--app-shell-hover-suppressed-value",
      ].includes(attribute);
    const pinState =
      this.hasPinTarget &&
      event.target === this.pinTarget &&
      attribute === "aria-pressed";

    if (sidebarState || pinState) event.preventDefault();
  }

  dialogClosed() {
    this.finishClosing();
  }

  syncViewport() {
    // A Turbo morph restores the server-rendered attributes without
    // reconnecting the controller, so the enhancement marker is re-asserted
    // every time the shell reconciles rather than only on connect.
    this.element.dataset.enhanced = "";

    if (
      !this.hasDialogTarget ||
      !this.hasNavigationTarget ||
      !this.hasSidebarTarget
    ) {
      return;
    }

    const enteringNarrow = this.wasNarrow === false && this.isNarrow;
    this.wasNarrow = this.isNarrow;
    if (this.isNarrow) this.hoverSuppressedValue = false;

    if (!this.isNarrow) {
      this.closeDialog({ restoreFocus: false });
      return;
    }

    if (
      enteringNarrow &&
      this.element.dataset.state !== "open" &&
      this.navigationTarget.contains(document.activeElement) &&
      this.hasTriggerTarget
    ) {
      this.triggerTarget.focus();
    }

    if (this.element.dataset.state === "open") {
      this.moveNavigationTo(this.dialogTarget);
      this.ensureModalDialog();
      this.setState(true);
    } else {
      this.closeDialog({ restoreFocus: false });
    }
  }

  dialogTargetConnected() {
    if (this.viewport) this.syncViewport();
  }

  dialogTargetDisconnected(dialog) {
    if (dialog.open) dialog.close();
  }

  navigationTargetConnected() {
    if (this.viewport) this.syncViewport();
  }

  sidebarTargetConnected() {
    if (this.viewport) this.syncViewport();
  }

  triggerTargetConnected(trigger) {
    this.syncTrigger(trigger);
  }

  openLabelValueChanged() {
    if (this.hasTriggerTarget) this.syncTrigger(this.triggerTarget);
  }

  closeLabelValueChanged() {
    if (this.hasTriggerTarget) this.syncTrigger(this.triggerTarget);
  }

  closeDialog({ restoreFocus = true } = {}) {
    this.restoreFocusAfterClose = restoreFocus;

    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close();
    } else {
      this.finishClosing();
    }
  }

  finishClosing() {
    const shouldRestoreFocus = this.restoreFocusAfterClose ?? true;
    const focusTarget = this.previouslyFocused?.isConnected
      ? this.previouslyFocused
      : this.hasTriggerTarget
      ? this.triggerTarget
      : null;

    this.restoreNavigation();
    this.setState(false);
    this.previouslyFocused = null;
    this.restoreFocusAfterClose = undefined;

    if (
      shouldRestoreFocus &&
      focusTarget?.isConnected &&
      document.activeElement !== focusTarget
    ) {
      focusTarget.focus();
    }
  }

  ensureModalDialog() {
    if (this.dialogTarget.matches(":modal")) return;

    if (this.dialogTarget.open) this.dialogTarget.close();
    this.dialogTarget.showModal();
  }

  restoreNavigation() {
    if (!this.hasNavigationTarget || !this.hasSidebarTarget) return;

    this.moveNavigationTo(this.sidebarTarget);
  }

  moveNavigationTo(container) {
    if (this.navigationTarget.parentElement !== container) {
      container.append(this.navigationTarget);
    }
  }

  setState(open) {
    this.element.dataset.state = open ? "open" : "closed";
    if (this.hasTriggerTarget) this.syncTrigger(this.triggerTarget);
  }

  syncTrigger(trigger) {
    const open = this.element.dataset.state === "open";
    trigger.setAttribute("aria-expanded", String(open));
    trigger.setAttribute(
      "aria-label",
      open ? this.closeLabelValue : this.openLabelValue,
    );
  }

  get isNarrow() {
    return this.viewport?.matches ?? false;
  }
}
