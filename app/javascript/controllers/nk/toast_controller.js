import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list", "template", "sink"];
  static values = {
    duration: { type: Number, default: 5000 },
  };

  connect() {
    this.#flushSink();

    if (this.hasSinkTarget) {
      this.mutationObserver = new MutationObserver(([event]) => {
        if (event.addedNodes.length === 0) return;
        this.#flushSink();
      });
      this.mutationObserver.observe(this.sinkTarget, { childList: true });
    }
  }

  disconnect() {
    if (this.mutationObserver) this.mutationObserver.disconnect();
  }

  toast({ params }) {
    const { title, description } = params;
    const item = this.templateTarget.content.cloneNode(true);

    item.querySelector("[data-slot=title]").textContent = title;
    item.querySelector("[data-slot=description]").textContent = description;

    this.show(item);
  }

  show(item) {
    this.clear();
    this.listTarget.appendChild(item);

    requestAnimationFrame(() => {
      this.listTarget.children[0].dataset.state = "open";
    });

    if (this.timer) clearTimeout(this.timer);

    this.timer = setTimeout(() => {
      this.hide();
    }, this.durationValue);
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

  #flushSink() {
    for (const li of this.sinkTarget.children) {
      this.show(li.cloneNode(true));
      li.remove();
    }
  }
}
