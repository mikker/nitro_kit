import { Controller } from "@hotwired/stimulus";
import Combobox from "@github/combobox-nav";
import {
  computePosition,
  offset,
  flip,
  shift,
  autoUpdate,
} from "@floating-ui/dom";

export default class extends Controller {
  static targets = ["input", "list", "hiddenField", "clearButton"];
  static values = {
    open: { type: Boolean, default: false },
    // Options for floating-ui
    placement: { type: String },
    // Options for combobox-nav
    tabInsertsSuggestions: { type: Boolean },
    firstOptionSelectionMode: { type: String },
    scrollIntoViewOptions: { type: Object },
  };

  connect() {
    this.combobox = new Combobox(this.inputTarget, this.listTarget, {
      tabInsertsSuggestions: this.tabInsertsSuggestionsValue,
      firstOptionSelectionMode: this.firstOptionSelectionModeValue,
      scrollIntoViewOptions: this.scrollIntoViewOptionsValue,
    });

    this.updatePosition();

    this.listTarget.addEventListener("combobox-commit", (event) => {
      this.select(event);
      this.close();
    });
  }

  disconnect() {
    this.combobox.destroy();
  }

  select(event) {
    this.inputTarget.value = event.target.textContent;
    this.hiddenFieldTarget.value =
      event.target.dataset.value || event.target.textContent;
  }

  open() {
    this.openValue = true;
  }

  close() {
    this.openValue = false;
  }

  focusShift({ target }) {
    if (!this.openValue) return;
    if (this.element.contains(target)) return;

    this.close();
  }

  windowClick({ target }) {
    if (!this.openValue) return;
    if (this.element.contains(target)) return;

    this.close();
  }

  clear() {
    this.combobox.resetSelection();
    this.inputTarget.value = "";
    this.input();
    this.hiddenFieldTarget.value = "";
  }

  input(_event) {
    if (!this.isOpen) this.open();

    const filter = this.inputTarget.value.toLowerCase();

    Array.from(this.listTarget.children).forEach((item) => {
      const value = item.dataset.value?.toLowerCase();
      const text = item.textContent.toLowerCase();

      if (value?.includes(filter) || text.includes(filter)) {
        item.setAttribute("role", "option");
      } else {
        item.removeAttribute("role");
      }
    });

    this.hiddenFieldTarget.value = this.inputTarget.value;
  }

  openValueChanged(state, _previous) {
    if (!this.combobox) return;

    if (state) {
      this.combobox.start();

      this.listTarget.dataset.state = "open";

      this.clearAutoUpdate = autoUpdate(
        this.inputTarget,
        this.listTarget,
        this.updatePosition,
      );
    } else {
      this.combobox.stop();

      this.listTarget.dataset.state = "closed";

      if (this.clearAutoUpdate) {
        this.clearAutoUpdate();
      }
    }
  }

  updatePosition = () => {
    computePosition(this.inputTarget, this.listTarget, {
      placement: this.placementValue,
      middleware: [offset(5), flip(), shift({ padding: 5 })],
    }).then(({ x, y }) => {
      this.listTarget.style.left = `${x}px`;
      this.listTarget.style.top = `${y}px`;
      this.listTarget.style.width = `${this.inputTarget.clientWidth}px`;
    });
  };
}
