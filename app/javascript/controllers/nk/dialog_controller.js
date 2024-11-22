import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "content"];

  connect() {
    console.log("dialog");
    this.open();
  }

  open() {
    this.contentTarget.showModal();
    console.log("open");
  }
}
