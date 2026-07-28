import { Controller } from "@hotwired/stimulus";

const submissionIndicatorDelay = 1000;

export default class extends Controller {
  connect() {
    this.form = this.element.form;
    this.submissionText = this.element.getAttribute("data-turbo-submits-with");
    this.initialAriaBusy = this.element.getAttribute("aria-busy");
    this.element.removeAttribute("data-turbo-submits-with");
  }

  disconnect() {
    this.reset();
  }

  submit(event) {
    if (event.submitter !== this.element) return;

    this.element.dataset.state = "submitting";
    this.element.setAttribute("aria-busy", "true");
    if (this.submissionSpinner) {
      this.indicatorTimer = setTimeout(() => {
        this.submissionSpinner.dataset.state = "visible";
      }, submissionIndicatorDelay);
    }
  }

  reset(event) {
    if (event?.type === "turbo:submit-end" && event.target !== this.form)
      return;

    delete this.element.dataset.state;
    clearTimeout(this.indicatorTimer);
    delete this.submissionSpinner?.dataset.state;
    if (this.initialAriaBusy === null) {
      this.element.removeAttribute("aria-busy");
    } else {
      this.element.setAttribute("aria-busy", this.initialAriaBusy);
    }
    if (event?.type === "turbo:before-cache") {
      if (this.submissionText !== null) {
        this.element.setAttribute(
          "data-turbo-submits-with",
          this.submissionText,
        );
      }
    }
  }

  get submissionSpinner() {
    return this.element.querySelector(
      '[data-slot="button-submission-spinner"]',
    );
  }
}
