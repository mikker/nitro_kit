import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "content"];

  toggle() {
    const isExpanded =
      this.triggerTarget.getAttribute("aria-expanded") === "true";

    // Toggle current item
    this.triggerTarget.setAttribute("aria-expanded", (!isExpanded).toString());
    this.contentTarget.setAttribute("aria-hidden", isExpanded.toString());
  }
}
