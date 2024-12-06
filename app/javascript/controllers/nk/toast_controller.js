import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list", "template"];

  show({ params }) {
    const { title, description } = params;
    const item = this.templateTarget.content.cloneNode(true);

    item.querySelector("[data-slot=title]").textContent = title;
    item.querySelector("[data-slot=description]").textContent = description;

    this.clear();
    this.listTarget.appendChild(item);

    requestAnimationFrame(() => {
      this.listTarget.children[0].dataset.state = "open";
    });

    if (this.timer) clearTimeout(this.timer);

    this.timer = setTimeout(() => {
      this.hide();
    }, 1000);
  }

  hide() {
    this.listTarget.children[0].dataset.state = "closed";

    setTimeout(() => {
      this.clear();
    }, 250);
  }

  clear() {
    this.listTarget.innerHTML = "";
  }
}