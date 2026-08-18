import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.restoreSections()
    this.sync()
    this.element.addEventListener("toggle", this.rememberSections, true)
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.rememberSections, true)
  }

  rememberScroll() {
    this.element.galleryScrollTop = this.body.scrollTop
  }

  // Toggled groups persist per tab; untouched groups keep the server's
  // default, and the group holding the current page always starts open so
  // navigation never lands somewhere invisible.
  restoreSections() {
    let stored = {}
    try {
      stored = JSON.parse(sessionStorage.getItem("gallery-sections") || "{}")
    } catch {
      stored = {}
    }

    for (const details of this.disclosures) {
      const label = this.sectionLabel(details)
      if (label in stored) details.open = stored[label]
      if (details.querySelector("[aria-current]")) details.open = true
    }
  }

  rememberSections = (event) => {
    const details = event.target
    if (details.dataset.slot !== "app-navigation-section-disclosure") return

    let stored = {}
    try {
      stored = JSON.parse(sessionStorage.getItem("gallery-sections") || "{}")
    } catch {
      stored = {}
    }
    stored[this.sectionLabel(details)] = details.open

    try {
      sessionStorage.setItem("gallery-sections", JSON.stringify(stored))
    } catch {
      // Private browsing without storage keeps working, without persistence.
    }
  }

  sectionLabel(details) {
    return details
      .querySelector("summary[data-slot='app-navigation-section-label']")
      .textContent.trim()
  }

  get disclosures() {
    return Array.from(
      this.element.querySelectorAll(
        "details[data-slot='app-navigation-section-disclosure']",
      ),
    )
  }

  sync() {
    const pathname = window.location.pathname

    for (const link of this.element.querySelectorAll(
      "[data-gallery-navigation-match]",
    )) {
      const [mode, match] = link.dataset.galleryNavigationMatch.split(":", 2)
      const current =
        mode === "prefix" ? pathname.startsWith(match) : pathname === match

      link.dataset.state = current ? "current" : "default"
      if (current) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    }

    if (Number.isFinite(this.element.galleryScrollTop)) {
      this.body.scrollTop = this.element.galleryScrollTop
    }
  }

  get body() {
    return this.element.querySelector(
      ":scope > [data-slot='app-navigation-body']",
    )
  }
}
