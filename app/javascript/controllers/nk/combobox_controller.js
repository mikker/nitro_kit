import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "value", "listbox", "option"];
  static values = { open: Boolean, required: Boolean };

  connect() {
    this.activeOption = null;
    this.syncSelection();
    this.syncValidity();
  }

  disconnect() {
    this.openValue = false;
    this.element.dataset.state = "closed";
    if (this.hasListboxTarget) {
      this.listboxTarget.dataset.state = "closed";
      this.listboxTarget.hidden = true;
    }
    if (this.hasInputTarget) {
      this.inputTarget.setAttribute("aria-expanded", "false");
      this.inputTarget.setCustomValidity("");
      this.inputTarget.removeAttribute("aria-activedescendant");
    }
  }

  open() {
    if (this.inputTarget.disabled) return;

    this.openValue = true;
  }

  close() {
    this.openValue = false;
    this.setActive(null);
  }

  closeFromOutside(event) {
    if (!this.element.contains(event.target)) this.close();
  }

  filter() {
    const query = this.inputTarget.value.trim().toLocaleLowerCase();
    let exactMatch = null;

    this.optionTargets.forEach((option) => {
      const label = this.optionLabel(option);
      option.hidden = !label.toLocaleLowerCase().includes(query);

      if (
        label.toLocaleLowerCase() === query &&
        option.getAttribute("aria-disabled") !== "true"
      ) {
        exactMatch = option;
      }
    });

    this.valueTarget.value = exactMatch?.dataset.value ?? "";
    this.syncSelection();
    this.setActive(null);
    this.syncValidity();
    this.open();
  }

  select(event) {
    this.commit(event.currentTarget);
  }

  activate(event) {
    this.setActive(event.currentTarget);
  }

  navigate(event) {
    const options = this.visibleOptions;
    const currentIndex = options.indexOf(this.activeOption);
    let nextIndex;

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        this.open();
        nextIndex = (currentIndex + 1) % options.length;
        break;
      case "ArrowUp":
        event.preventDefault();
        this.open();
        nextIndex = (currentIndex - 1 + options.length) % options.length;
        break;
      case "Home":
        if (!this.openValue) return;
        event.preventDefault();
        nextIndex = 0;
        break;
      case "End":
        if (!this.openValue) return;
        event.preventDefault();
        nextIndex = options.length - 1;
        break;
      case "Enter":
        if (!this.openValue || !this.activeOption) return;
        event.preventDefault();
        this.commit(this.activeOption);
        return;
      case "Escape":
        if (!this.openValue) return;
        event.preventDefault();
        this.close();
        return;
      case "Tab":
        this.close();
        this.syncValidity();
        return;
      default:
        return;
    }

    if (options.length > 0) this.setActive(options[nextIndex]);
  }

  validate() {
    this.syncValidity();
  }

  openValueChanged(open) {
    const state = open ? "open" : "closed";
    this.element.dataset.state = state;
    this.listboxTarget.dataset.state = state;
    this.listboxTarget.hidden = !open;
    this.inputTarget.setAttribute("aria-expanded", String(open));

    if (open && !this.activeOption) {
      const selected = this.optionTargets.find(
        (option) =>
          option.getAttribute("aria-selected") === "true" && !option.hidden,
      );
      this.setActive(selected ?? this.visibleOptions[0] ?? null);
    }
  }

  commit(option) {
    if (!option || option.getAttribute("aria-disabled") === "true") return;

    this.inputTarget.value = this.optionLabel(option);
    this.valueTarget.value = option.dataset.value;
    this.syncSelection();
    this.syncValidity();
    this.close();
    this.inputTarget.focus();
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }

  syncSelection() {
    this.optionTargets.forEach((option) => {
      const selected = option.dataset.value === this.valueTarget.value;
      option.setAttribute("aria-selected", String(selected));
      option.dataset.state = selected ? "selected" : "unselected";
    });
  }

  syncValidity() {
    const hasVisibleValue = this.inputTarget.value.trim() !== "";
    const hasSubmittedValue = this.valueTarget.value !== "";
    const invalid =
      (this.requiredValue && !hasSubmittedValue) ||
      (hasVisibleValue && !hasSubmittedValue);
    this.inputTarget.setCustomValidity(invalid ? "Choose an option." : "");
    this.inputTarget.setAttribute("aria-invalid", String(invalid));
  }

  setActive(option) {
    this.optionTargets.forEach((candidate) => {
      candidate.dataset.active = String(candidate === option);
    });

    this.activeOption = option;

    if (option) {
      this.inputTarget.setAttribute("aria-activedescendant", option.id);
      option.scrollIntoView({ block: "nearest" });
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant");
    }
  }

  optionLabel(option) {
    return option.textContent.trim();
  }

  get visibleOptions() {
    return this.optionTargets.filter(
      (option) =>
        !option.hidden && option.getAttribute("aria-disabled") !== "true",
    );
  }
}
