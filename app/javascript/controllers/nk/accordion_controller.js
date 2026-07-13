import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item", "trigger", "content"];
  static values = { mode: { type: String, default: "multiple" } };

  toggle(event) {
    const trigger = event.currentTarget;
    const item = trigger.closest("[data-slot='accordion-item']");
    const content = item?.querySelector(
      "[data-nk--accordion-target='content']",
    );

    if (!item || !content || trigger.disabled) return;

    const expanded = trigger.getAttribute("aria-expanded") === "true";

    if (!expanded && this.modeValue === "single") {
      this.itemTargets
        .filter((candidate) => candidate !== item)
        .forEach((candidate) => this.setExpanded(candidate, false));
    }

    this.setExpanded(item, !expanded);
  }

  setExpanded(item, expanded) {
    const trigger = item.querySelector("[data-nk--accordion-target='trigger']");
    const content = item.querySelector("[data-nk--accordion-target='content']");

    if (!trigger || !content) return;

    const state = expanded ? "open" : "closed";

    trigger.setAttribute("aria-expanded", String(expanded));
    content.hidden = !expanded;
    content.setAttribute("aria-hidden", String(!expanded));
    item.dataset.state = state;
    content.dataset.state = state;
  }
}
