import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "button", "successMessage"];

  async copy(event) {
    event.preventDefault();

    const text = this.sourceTarget.value || this.sourceTarget.textContent;

    try {
      await navigator.clipboard.writeText(text);
      this.showSuccess();
    } catch (err) {
      console.error("Failed to copy text:", err);
    }
  }

  showSuccess() {
    this.buttonTarget.setAttribute("aria-hidden", "true");
    this.buttonTarget.style.display = "none";
    this.successMessageTarget.removeAttribute("aria-hidden");
    this.successMessageTarget.style.display = "inline-flex";

    setTimeout(() => {
      this.buttonTarget.setAttribute("aria-hidden", "false");
      this.buttonTarget.style.display = "inline-flex";
      this.successMessageTarget.classList.add("hidden");
      this.successMessageTarget.style.display = "none";
    }, 2000);
  }
}
