import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item"];
  static values = { duration: Number };

  connect() {
    this.timers ||= new Map();
  }

  disconnect() {
    this.timers?.forEach((timers) => {
      window.clearTimeout(timers.dismiss);
      window.clearTimeout(timers.remove);
    });
    this.timers?.clear();
  }

  itemTargetConnected(item) {
    this.schedule(item);
  }

  itemTargetDisconnected(item) {
    this.clear(item);
  }

  dismiss(event) {
    const item = event.currentTarget.closest('[data-nk="toast-item"]');
    if (item) this.close(item);
  }

  pause(event) {
    const item = event.currentTarget;
    const timers = this.timerMap.get(item);
    if (!timers?.dismiss) return;

    window.clearTimeout(timers.dismiss);
    timers.dismiss = null;
    timers.remaining = Math.max(0, timers.deadline - Date.now());
  }

  resume(event) {
    const item = event.currentTarget;
    if (item.contains(event.relatedTarget)) return;
    if (item.dataset.state !== "open") return;

    const remaining = this.timerMap.get(item)?.remaining ?? this.durationValue;
    this.schedule(item, remaining);
  }

  remove(event) {
    if (event.target !== event.currentTarget) return;
    if (event.currentTarget.dataset.state !== "closed") return;

    this.removeItem(event.currentTarget);
  }

  schedule(item, delay = this.durationValue) {
    this.clear(item);
    if (item.dataset.state !== "open") return;
    if (item.hasAttribute("data-nk--toast-permanent")) return;

    const dismiss = window.setTimeout(() => this.close(item), delay);
    this.timerMap.set(item, {
      dismiss,
      remove: null,
      deadline: Date.now() + delay,
      remaining: delay,
    });
  }

  close(item) {
    if (!item.isConnected || item.dataset.state === "closed") return;

    this.clear(item);
    item.dataset.state = "closed";

    const remove = window.setTimeout(() => this.removeItem(item), 200);
    this.timerMap.set(item, {
      dismiss: null,
      remove,
      deadline: null,
      remaining: null,
    });
  }

  removeItem(item) {
    this.clear(item);
    item.remove();
  }

  clear(item) {
    const timers = this.timerMap.get(item);
    if (!timers) return;

    window.clearTimeout(timers.dismiss);
    window.clearTimeout(timers.remove);
    this.timerMap.delete(item);
  }

  get timerMap() {
    this.timers ||= new Map();
    return this.timers;
  }
}
