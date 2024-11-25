import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "content"];

  toggle(event) {
    const trigger = event.target;
    const content = trigger.parentElement.querySelector(
      "[data-nk--accordion-target=content]",
    );

    const isExpanded = trigger.getAttribute("aria-expanded") === "true";

    // Toggle current item
    trigger.setAttribute("aria-expanded", (!isExpanded).toString());
    content.setAttribute("aria-hidden", isExpanded.toString());
  }
}
