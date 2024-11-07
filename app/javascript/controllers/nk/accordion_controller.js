import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "content"];

  toggle(event) {
    const trigger = event.currentTarget;
    const content = trigger.nextElementSibling;
    const isExpanded = trigger.getAttribute("aria-expanded") === "true";

    // Close all other items in the accordion
    // this.triggerTargets.forEach((otherTrigger) => {
    //   if (otherTrigger !== trigger) {
    //     otherTrigger.setAttribute("aria-expanded", "false");
    //     otherTrigger.nextElementSibling.setAttribute("aria-hidden", "true");
    //   }
    // });

    // Toggle current item
    trigger.setAttribute("aria-expanded", (!isExpanded).toString());
    content.setAttribute("aria-hidden", isExpanded.toString());
  }
}
