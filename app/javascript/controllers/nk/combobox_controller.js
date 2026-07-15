import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "control",
    "input",
    "native",
    "value",
    "listbox",
    "option",
    "status",
  ];
  static values = { open: Boolean, required: Boolean };

  connect() {
    this.activeOption = null;
    this.enhanced = true;
    this.nativeRequired = this.requiredValue;
    this.element.dataset.enhanced = "true";
    this.controlTarget.hidden = false;
    this.nativeTarget.hidden = true;
    this.valueTarget.required = false;
    this.syncSelection();
    this.syncValidity();
    this.reflectOpenState();
  }

  disconnect() {
    this.enhanced = false;
    const control = this.element.querySelector(
      ':scope > [data-slot="combobox-control"]',
    );
    const input = control?.querySelector('[data-nk--combobox-target~="input"]');
    const native = this.element.querySelector(
      ':scope > [data-slot="combobox-native"]',
    );
    const value = native?.querySelector('[data-nk--combobox-target~="value"]');
    const listbox = this.element.querySelector(
      ':scope > [data-slot="combobox-listbox"]',
    );
    const status = this.element.querySelector(
      ':scope > [data-slot="combobox-status"]',
    );

    this.element.setAttribute("data-nk--combobox-open-value", "false");
    this.element.dataset.state = "closed";
    if (listbox) {
      listbox.dataset.state = "closed";
      listbox.hidden = true;
    }
    if (input) {
      input.setAttribute("aria-expanded", "false");
      input.setCustomValidity("");
      input.removeAttribute("aria-activedescendant");
    }
    if (control) control.hidden = true;
    if (native) native.hidden = false;
    if (value) value.required = this.nativeRequired;
    if (status) status.textContent = "";
    delete this.element.dataset.enhanced;
  }

  controlTargetConnected(control) {
    if (this.enhanced) control.hidden = false;
  }

  nativeTargetConnected(native) {
    if (this.enhanced) native.hidden = true;
  }

  valueTargetConnected(value) {
    if (!this.enhanced) return;

    this.nativeRequired = this.requiredValue;
    value.required = false;
    if (this.hasInputTarget) {
      this.syncSelection();
      this.syncValidity();
    }
  }

  inputTargetConnected() {
    if (!this.enhanced) return;

    if (this.hasValueTarget) this.syncValidity();
    this.reflectOpenState();
  }

  inputTargetDisconnected() {
    this.activeOption = null;
  }

  listboxTargetConnected() {
    if (this.enhanced) this.reflectOpenState();
  }

  optionTargetConnected() {
    if (this.enhanced && this.hasValueTarget) this.syncSelection();
  }

  optionTargetDisconnected(option) {
    if (this.activeOption === option) this.setActive(null);
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
    this.announceResults();
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
    if (!this.enhanced) return;

    this.reflectOpenState(open);
  }

  reflectOpenState(open = this.openValue) {
    if (!this.hasListboxTarget || !this.hasInputTarget) return;

    const state = open ? "open" : "closed";
    this.element.dataset.state = state;
    this.listboxTarget.dataset.state = state;
    this.listboxTarget.hidden = !open;
    this.inputTarget.setAttribute("aria-expanded", String(open));

    if (open && (!this.activeOption || !this.activeOption.isConnected)) {
      const selected = this.optionTargets.find(
        (option) =>
          option.getAttribute("aria-selected") === "true" && !option.hidden,
      );
      this.setActive(selected ?? this.visibleOptions[0] ?? null);
    } else if (open && this.activeOption) {
      this.inputTarget.setAttribute(
        "aria-activedescendant",
        this.activeOption.id,
      );
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

    if (option && this.hasInputTarget) {
      this.inputTarget.setAttribute("aria-activedescendant", option.id);
      option.scrollIntoView({ block: "nearest" });
    } else if (this.hasInputTarget) {
      this.inputTarget.removeAttribute("aria-activedescendant");
    }
  }

  optionLabel(option) {
    return option.textContent.trim();
  }

  announceResults() {
    const count = this.optionTargets.filter((option) => !option.hidden).length;

    if (count === 0) {
      this.statusTarget.textContent = "No options found.";
    } else {
      this.statusTarget.textContent = `${count} ${count === 1 ? "option" : "options"} available.`;
    }
  }

  get visibleOptions() {
    return this.optionTargets.filter(
      (option) =>
        !option.hidden && option.getAttribute("aria-disabled") !== "true",
    );
  }
}
