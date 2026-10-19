import { Controller } from "@hotwired/stimulus";
import {
  observeOverlayPosition,
  positionOverlay,
} from "controllers/nk/overlay_position";
import { fetchResults, LatestRequest } from "controllers/nk/combobox_remote";

// The Combobox component translates these and passes them in as Stimulus
// values. They remain here as the shipped English fallbacks.
const INVALID_SELECTION_MESSAGE = "Choose an option.";
const NO_RESULTS_MESSAGE = "No options found.";
const RESULTS_ONE_MESSAGE = "%{count} option available.";
const RESULTS_OTHER_MESSAGE = "%{count} options available.";
const LOADING_MESSAGE = "Searching…";
const ERROR_MESSAGE = "Results could not be loaded. Try again.";
const REMOVE_MESSAGE = "Remove %{label}";

const OPTION_LABEL_SELECTOR = '[data-slot="combobox-option-label"]';
const SEARCH_DELAY = 150;

export default class extends Controller {
  static targets = [
    "control",
    "input",
    "native",
    "value",
    "listbox",
    "option",
    "status",
    "message",
    "selections",
    "selection",
    "selectionTemplate",
  ];
  static values = {
    open: Boolean,
    required: Boolean,
    invalidSelection: String,
    noResults: String,
    resultsOne: String,
    resultsOther: String,
    src: String,
    multiple: Boolean,
    loading: String,
    error: String,
    remove: String,
  };

  get invalidSelectionMessage() {
    return this.invalidSelectionValue || INVALID_SELECTION_MESSAGE;
  }

  get noResultsMessage() {
    return this.noResultsValue || NO_RESULTS_MESSAGE;
  }

  get loadingMessage() {
    return this.loadingValue || LOADING_MESSAGE;
  }

  get errorMessage() {
    return this.errorValue || ERROR_MESSAGE;
  }

  resultsMessage(count) {
    const template =
      count === 1
        ? this.resultsOneValue || RESULTS_ONE_MESSAGE
        : this.resultsOtherValue || RESULTS_OTHER_MESSAGE;

    return template.replace("%{count}", String(count));
  }

  removeMessage(label) {
    return (this.removeValue || REMOVE_MESSAGE).replace("%{label}", label);
  }

  get remote() {
    return this.srcValue !== "";
  }

  connect() {
    this.outsidePointerDown = this.outsidePointerDown.bind(this);
    this.activeOption = null;
    this.enhanced = true;
    this.searches = new LatestRequest();
    this.loadedQuery = null;
    this.nativeRequired = this.requiredValue;
    this.element.dataset.enhanced = "true";
    if (this.hasNativeTarget) {
      this.controlTarget.hidden = false;
      this.nativeTarget.hidden = true;
      this.valueTarget.required = false;
    }
    this.syncSelection();
    this.syncValidity();
    this.reflectOpenState();
  }

  disconnect() {
    this.stopPositioning?.();
    this.stopOutsideDismissal();
    clearTimeout(this.searchTimer);
    this.searches?.cancel();
    this.enhanced = false;
    const controlSlot = this.element.querySelector(
      ':scope > [data-slot="combobox-control"]',
    );
    const input = controlSlot?.querySelector(
      '[data-nk--combobox-target~="input"]',
    );
    const native = this.element.querySelector(
      ':scope > [data-slot="combobox-native"]',
    );
    // A remote combobox has no native fallback, so its control stays visible.
    const control = native ? controlSlot : null;
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
      listbox.removeAttribute("aria-busy");
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

    if (this.hasValueTarget || this.multipleValue) this.syncValidity();
    this.reflectOpenState();
  }

  inputTargetDisconnected() {
    this.activeOption = null;
  }

  listboxTargetConnected() {
    if (this.enhanced) this.reflectOpenState();
  }

  optionTargetConnected(option) {
    if (this.enhanced) this.syncOption(option, this.selectedValues);
  }

  optionTargetDisconnected(option) {
    if (this.activeOption === option) this.setActive(null);
  }

  open() {
    if (this.inputTarget.disabled) return;

    // A committed single selection is replaced, not appended to: opening
    // selects the visible text so the first keystroke starts a fresh filter.
    if (
      !this.openValue &&
      !this.multipleValue &&
      this.inputTarget.value !== ""
    ) {
      this.inputTarget.select();
      this.inputTarget.addEventListener(
        "mouseup",
        (event) => event.preventDefault(),
        { once: true },
      );
    }

    this.openValue = true;
    if (this.remote && this.loadedQuery !== this.query) this.search();
  }

  close() {
    this.openValue = false;
    this.setActive(null);
  }

  // Capture-phase document pointerdown mirrors the Dropdown controller: iOS
  // Safari does not reliably deliver window click events for outside taps.
  outsidePointerDown(event) {
    if (!this.element.contains(event.target)) this.close();
  }

  startOutsideDismissal() {
    if (this.stopOutsideDismissalListener) return;

    document.addEventListener("pointerdown", this.outsidePointerDown, true);
    this.stopOutsideDismissalListener = () => {
      document.removeEventListener(
        "pointerdown",
        this.outsidePointerDown,
        true,
      );
      this.stopOutsideDismissalListener = null;
    };
  }

  stopOutsideDismissal() {
    this.stopOutsideDismissalListener?.();
  }

  filter() {
    if (this.remote) {
      this.filterRemote();
      return;
    }

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

    this.setSubmittedValue(exactMatch?.dataset.value ?? "");
    this.syncSelection();
    this.setActive(null);
    this.syncValidity();
    this.announceResults();
    this.open();
  }

  // Remote results come from the application's search endpoint. Typing
  // replaces a committed single selection; in multiple mode the text is only
  // a query and the chips keep their values.
  filterRemote() {
    if (!this.multipleValue) this.setSubmittedValue("");
    this.syncSelection();
    this.setActive(null);
    this.syncValidity();
    this.openValue = true;
    this.listboxTarget.setAttribute("aria-busy", "true");
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.search(), SEARCH_DELAY);
  }

  get query() {
    if (!this.multipleValue && this.hasValueTarget && this.valueTarget.value)
      return "";

    return this.inputTarget.value.trim();
  }

  async search(query = this.query) {
    clearTimeout(this.searchTimer);
    const url = new URL(this.srcValue, document.baseURI);
    url.searchParams.set("query", query);
    this.listboxTarget.setAttribute("aria-busy", "true");
    if (this.resultOptions.length === 0) this.showMessage("loading");

    try {
      const items = await this.searches.run((signal) =>
        fetchResults(url, { signal }),
      );
      // A newer search, a creation, or a disconnect superseded this one.
      if (!items || !this.enhanced) return;

      this.loadedQuery = query;
      this.replaceResults(items);
    } catch (error) {
      if (!this.enhanced || this.searches.isStale(error)) return;

      this.showError();
    }
  }

  replaceResults(items) {
    this.setActive(null);
    this.resultOptions.forEach((option) => option.remove());
    this.messageTarget.before(...items);
    this.listboxTarget.removeAttribute("aria-busy");
    this.syncSelection();
    this.announceResults();
    this.updatePosition?.();
  }

  showError() {
    this.loadedQuery = null;
    this.setActive(null);
    this.resultOptions.forEach((option) => option.remove());
    this.listboxTarget.removeAttribute("aria-busy");
    this.showMessage("error");
    this.statusTarget.textContent = this.errorMessage;
    this.updatePosition?.();
  }

  showMessage(state) {
    const messages = {
      loading: this.loadingMessage,
      error: this.errorMessage,
      empty: this.noResultsMessage,
    };

    this.messageTarget.dataset.state = state;
    this.messageTarget.textContent = messages[state] ?? "";
    this.messageTarget.hidden = !(state in messages);
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
        if (!this.openValue) return;
        // An open remote search never submits the surrounding form: Enter
        // belongs to the results, even while they are still loading.
        if (this.remote) event.preventDefault();
        if (!this.activeOption) return;
        event.preventDefault();
        this.commit(this.activeOption);
        return;
      case "Escape":
        if (!this.openValue) return;
        event.preventDefault();
        this.close();
        return;
      case "Backspace":
        if (
          !this.multipleValue ||
          this.inputTarget.value !== "" ||
          this.selectionTargets.length === 0
        )
          return;
        event.preventDefault();
        this.removeSelection(this.selectionTargets.at(-1));
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

    if (open) {
      this.startPositioning();
      this.startOutsideDismissal();
    } else {
      this.stopPositioning?.();
      this.stopPositioning = null;
      this.updatePosition = null;
      this.stopOutsideDismissal();
    }
  }

  startPositioning() {
    this.stopPositioning?.();
    const update = () =>
      positionOverlay(
        this.inputTarget,
        this.listboxTarget,
        this.element.dataset.placement,
      );

    update();
    this.updatePosition = update;
    this.stopPositioning = observeOverlayPosition(update);
  }

  commit(option) {
    if (!option || option.getAttribute("aria-disabled") === "true") return;

    if (option.dataset.requestUrl) {
      this.runAction(option);
      return;
    }

    if (this.multipleValue) {
      this.toggleSelection(option);
      return;
    }

    this.inputTarget.value = this.optionLabel(option);
    this.setSubmittedValue(option.dataset.value);
    this.syncSelection();
    this.syncValidity();
    this.close();
    this.inputTarget.focus();
  }

  // A result action (such as "Create …") posts to the application, which
  // persists the record and answers with Combobox::Results holding it. The
  // first returned option becomes a selection exactly as if it were chosen.
  async runAction(option) {
    if (this.actionPending) return;

    this.actionPending = true;
    clearTimeout(this.searchTimer);
    this.searches.cancel();
    option.setAttribute("aria-busy", "true");
    this.listboxTarget.setAttribute("aria-busy", "true");

    try {
      const items = await fetchResults(option.dataset.requestUrl, {
        method: option.dataset.requestMethod,
        params: JSON.parse(option.dataset.requestParams || "{}"),
      });
      if (!this.enhanced) return;

      const created = items.find((item) => item.dataset.value !== undefined);
      if (!created) throw new Error("Combobox action returned no option");

      this.listboxTarget.removeAttribute("aria-busy");
      this.loadedQuery = null;
      this.commit(created);
      if (this.multipleValue && this.openValue) this.search();
    } catch (error) {
      if (this.enhanced) this.showError();
    } finally {
      this.actionPending = false;
      option.removeAttribute("aria-busy");
    }
  }

  toggleSelection(option) {
    const existing = this.selectionTargets.find(
      (selection) => selection.dataset.value === option.dataset.value,
    );

    if (existing) {
      existing.remove();
    } else {
      this.selectionsTarget.append(
        this.buildSelection(this.optionLabel(option), option.dataset.value),
      );
    }

    this.selectionsChanged();
    this.inputTarget.focus();
  }

  buildSelection(label, value) {
    const selection =
      this.selectionTemplateTarget.content.firstElementChild.cloneNode(true);

    selection.dataset.value = value;
    selection.querySelector(
      '[data-slot="combobox-selection-label"]',
    ).textContent = label;
    selection
      .querySelector('[data-slot="combobox-remove"]')
      .setAttribute("aria-label", this.removeMessage(label));
    selection.querySelector('[data-slot="combobox-selection-value"]').value =
      value;

    return selection;
  }

  remove(event) {
    const selection = event.currentTarget.closest(
      '[data-slot="combobox-selection"]',
    );
    const selections = this.selectionTargets;
    const index = selections.indexOf(selection);
    const neighbour = selections[index + 1] ?? selections[index - 1];

    this.removeSelection(selection);
    (
      neighbour?.querySelector('[data-slot="combobox-remove"]') ??
      this.inputTarget
    ).focus();
  }

  removeSelection(selection) {
    if (!selection || this.inputTarget.disabled) return;

    selection.remove();
    this.selectionsChanged();
  }

  // Chips hold their own hidden `name[]` fields, so removing a chip removes
  // its submitted value. The list itself carries the one bubbling change.
  selectionsChanged() {
    this.syncSelection();
    this.syncValidity();
    this.selectionsTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }

  setSubmittedValue(value) {
    if (this.valueTarget.value === value) return;

    this.valueTarget.value = value;
    this.valueTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }

  get selectedValues() {
    if (this.multipleValue)
      return new Set(
        this.selectionTargets.map((selection) => selection.dataset.value),
      );

    return new Set(this.hasValueTarget ? [this.valueTarget.value] : []);
  }

  syncSelection() {
    const values = this.selectedValues;
    this.optionTargets.forEach((option) => this.syncOption(option, values));
  }

  syncOption(option, values) {
    if (option.dataset.requestUrl) return;

    const selected = values.has(option.dataset.value);
    option.setAttribute("aria-selected", String(selected));
    option.dataset.state = selected ? "selected" : "unselected";
  }

  syncValidity() {
    if (!this.hasInputTarget) return;

    let invalid;
    if (this.multipleValue) {
      invalid = this.requiredValue && this.selectionTargets.length === 0;
    } else {
      const hasVisibleValue = this.inputTarget.value.trim() !== "";
      const hasSubmittedValue = this.valueTarget.value !== "";
      invalid =
        (this.requiredValue && !hasSubmittedValue) ||
        (hasVisibleValue && !hasSubmittedValue);
    }

    this.inputTarget.setCustomValidity(
      invalid ? this.invalidSelectionMessage : "",
    );
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
    const label = option.querySelector(OPTION_LABEL_SELECTOR) ?? option;

    return label.textContent.trim();
  }

  announceResults() {
    const count = this.optionTargets.filter((option) => !option.hidden).length;

    this.statusTarget.textContent =
      count === 0 ? this.noResultsMessage : this.resultsMessage(count);
    this.toggleEmptyState(count === 0);
  }

  toggleEmptyState(empty) {
    if (this.hasMessageTarget) {
      this.showMessage(empty ? "empty" : "idle");
      return;
    }

    if (empty && !this.emptyElement) {
      const item = document.createElement("li");
      item.setAttribute("role", "presentation");
      item.setAttribute("data-slot", "combobox-empty");
      item.textContent = this.noResultsMessage;
      this.listboxTarget.append(item);
      this.emptyElement = item;
    } else if (!empty && this.emptyElement) {
      this.emptyElement.remove();
      this.emptyElement = null;
    }
  }

  // Remote result items are every listbox child the server rendered: options
  // and actions, but never the controller-owned message.
  get resultOptions() {
    return Array.from(this.listboxTarget.children).filter(
      (child) => !this.messageTarget.contains(child),
    );
  }

  get visibleOptions() {
    return this.optionTargets.filter(
      (option) =>
        !option.hidden && option.getAttribute("aria-disabled") !== "true",
    );
  }
}
