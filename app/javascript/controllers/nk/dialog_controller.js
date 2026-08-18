import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel"];
  static values = { dismissible: Boolean };

  disconnect() {
    this.returnFocus = null;
  }

  invoke(event) {
    const invoker = event.target.closest(
      "[command], [data-nk--dialog-command]",
    );
    if (!invoker || !this.element.contains(invoker) || invoker.disabled) return;

    const command =
      invoker.getAttribute("command") ||
      invoker.getAttribute("data-nk--dialog-command");
    if (!["show-modal", "close"].includes(command)) return;

    const panel = this.#commandPanel(invoker);
    if (!panel) return;
    if (command === "show-modal" && !this.#canShowModal(invoker, panel)) {
      event.preventDefault();
      return;
    }
    if (command === "show-modal") this.returnFocus = invoker;
    if (this.#nativeRelationshipRuns(invoker, panel, command)) return;

    event.preventDefault();
    if (command === "show-modal" && !panel.open) panel.showModal();
    if (command === "close" && panel.open) panel.close();
  }

  closeForCache() {
    this.returnFocus = null;
    if (this.panelTarget.open) this.panelTarget.close();
  }

  restoreFocus() {
    const returnFocus = this.returnFocus;

    this.returnFocus = null;
    if (returnFocus?.isConnected) returnFocus.focus();
  }

  dismiss(event) {
    if (!this.dismissibleValue || event.target !== this.panelTarget) return;

    const rect = this.panelTarget.getBoundingClientRect();
    const inside =
      event.clientX >= rect.left &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom;

    if (!inside) this.panelTarget.close();
  }

  cancel(event) {
    if (!this.dismissibleValue) event.preventDefault();
  }

  #commandPanel(invoker) {
    const targetId = invoker.getAttribute("commandfor");
    if (targetId) {
      const target = document.getElementById(targetId);
      if (target instanceof HTMLDialogElement && this.element.contains(target))
        return target;
    }

    return invoker.hasAttribute("data-nk--dialog-command")
      ? this.panelTarget
      : null;
  }

  #nativeRelationshipRuns(invoker, panel, command) {
    return invoker.commandForElement === panel && invoker.command === command;
  }

  #canShowModal(invoker, panel) {
    if (panel.open) return false;

    const activeModal = document.querySelector("dialog:modal");
    return !activeModal || activeModal.contains(invoker);
  }
}
