import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "trigger",
    "panel",
    "search",
    "form",
    "frame",
    "input",
    "destination",
    "empty",
    "status",
  ];
  static values = {
    empty: String,
    resultsOne: String,
    resultsOther: String,
  };

  connect() {
    this.connected = true;
    this.restoreFocus = true;
    this.loadedQuery = this.inputTarget.value;
    this.searchTarget.hidden = false;
    this.element.dataset.enhanced = "true";
  }

  disconnect() {
    this.connected = false;
    clearTimeout(this.openTimer);
    clearTimeout(this.searchTimer);
    const trigger = this.element.querySelector(
      ':scope > [data-slot="command-palette-trigger"]',
    );
    const panel = this.element.querySelector(
      ':scope > [data-slot="command-palette-panel"]',
    );
    const search = panel?.querySelector('[data-slot="command-palette-search"]');
    const input = panel?.querySelector('[data-slot="command-palette-input"]');
    const empty = panel?.querySelector('[data-slot="command-palette-empty"]');
    const status = panel?.querySelector('[data-slot="command-palette-status"]');

    this.restoreFocus = false;
    if (panel?.open) panel.close();
    if (input) input.value = "";
    panel
      ?.querySelectorAll('[data-slot="command-palette-destination"]')
      .forEach((destination) => {
        destination.hidden = false;
      });
    if (empty) empty.hidden = true;
    if (status) status.textContent = "";
    if (search) search.hidden = true;
    delete this.element.dataset.enhanced;
  }

  openedByTrigger(event) {
    if (!this.canOpen) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    this.returnFocus = event.currentTarget;
    this.restoreFocus = true;
    clearTimeout(this.openTimer);
    this.openTimer = setTimeout(() => this.#prepareOpenPanel(), 0);
  }

  guardOpen(event) {
    if (event.command === "show-modal" && !this.canOpen) event.preventDefault();
  }

  shortcut(event) {
    if (
      event.defaultPrevented ||
      event.repeat ||
      event.isComposing ||
      event.altKey ||
      event.shiftKey ||
      event.key.toLocaleLowerCase() !== "k" ||
      (!event.metaKey && !event.ctrlKey)
    )
      return;

    if (this.panelTarget.open) {
      event.preventDefault();
      this.panelTarget.close();
    } else {
      if (!this.canOpen) return;

      event.preventDefault();
      this.returnFocus = document.activeElement;
      this.panelTarget.showModal();
      this.#prepareOpenPanel();
    }
  }

  filter() {
    const query = this.inputTarget.value.trim().toLocaleLowerCase();

    this.destinationTargets.forEach((destination) => {
      destination.hidden = !destination.textContent
        .toLocaleLowerCase()
        .includes(query);
    });

    this.updateResultState();
  }

  search() {
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => this.submitSearch(), 150);
  }

  navigateInput(event) {
    const destinations = this.visibleDestinations;

    if (
      event.key === "Enter" &&
      this.hasFormTarget &&
      this.inputTarget.value !== this.loadedQuery
    ) {
      event.preventDefault();
      this.submitSearch();
      return;
    }

    if (destinations.length === 0) return;

    if (event.key === "Enter") {
      event.preventDefault();
      destinations[0].click();
    } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      (event.key === "ArrowDown"
        ? destinations[0]
        : destinations.at(-1)
      ).focus();
    }
  }

  navigateDestination(event) {
    const destinations = this.visibleDestinations;
    const currentIndex = destinations.indexOf(event.currentTarget);
    const nextIndex = {
      ArrowDown: (currentIndex + 1) % destinations.length,
      ArrowUp: (currentIndex - 1 + destinations.length) % destinations.length,
      Home: 0,
      End: destinations.length - 1,
    }[event.key];

    if (nextIndex === undefined) return;

    event.preventDefault();
    destinations[nextIndex].focus();
  }

  select() {
    this.restoreFocus = false;
    this.panelTarget.close();
  }

  closeForVisit() {
    if (!this.panelTarget.open) return;

    this.restoreFocus = false;
    this.panelTarget.close();
  }

  loading() {
    this.frameTarget.setAttribute("aria-busy", "true");
  }

  loaded() {
    this.frameTarget.removeAttribute("aria-busy");
  }

  destinationTargetConnected() {
    this.scheduleResultUpdate();
  }

  destinationTargetDisconnected() {
    this.scheduleResultUpdate();
  }

  scheduleResultUpdate() {
    if (this.resultUpdateScheduled) return;

    this.resultUpdateScheduled = true;
    queueMicrotask(() => {
      this.resultUpdateScheduled = false;
      if (!this.connected || !this.panelTarget.open || !this.hasFormTarget)
        return;

      this.loadedQuery = this.inputTarget.value;
      this.updateResultState();
    });
  }

  closed() {
    const returnFocus = this.returnFocus;

    this.reset();
    this.returnFocus = null;
    if (this.restoreFocus && returnFocus?.isConnected) returnFocus.focus();
    this.restoreFocus = true;
  }

  reset() {
    clearTimeout(this.searchTimer);
    if (this.hasInputTarget) this.inputTarget.value = "";
    this.destinationTargets.forEach((destination) => {
      destination.hidden = false;
    });
    if (this.hasEmptyTarget) this.emptyTarget.hidden = true;
    if (this.hasStatusTarget) this.statusTarget.textContent = "";
  }

  resultsMessage(count) {
    const template =
      count === 1 ? this.resultsOneValue : this.resultsOtherValue;

    return template.replace("%{count}", String(count));
  }

  submitSearch() {
    clearTimeout(this.searchTimer);
    this.formTarget.requestSubmit();
  }

  updateResultState() {
    const count = this.visibleDestinations.length;
    this.emptyTarget.hidden = count !== 0;
    this.statusTarget.textContent =
      count === 0 ? this.emptyValue : this.resultsMessage(count);
  }

  get visibleDestinations() {
    return this.destinationTargets.filter((destination) => !destination.hidden);
  }

  get canOpen() {
    if (
      this.panelTarget.open ||
      this.triggerTarget.getClientRects().length === 0
    )
      return false;

    const activeModal = document.querySelector("dialog:modal");

    return !activeModal || activeModal.contains(this.element);
  }

  #prepareOpenPanel() {
    if (!this.panelTarget.open) return;

    this.reset();
    this.inputTarget.focus();
    if (this.hasFormTarget) this.submitSearch();
  }
}
