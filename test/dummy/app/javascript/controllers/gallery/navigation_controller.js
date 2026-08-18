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

  // Collapsed groups persist per tab; the group holding the current page
  // always reopens so navigation never lands somewhere invisible.
  restoreSections() {
    let collapsed = []
    try {
      collapsed = JSON.parse(
        sessionStorage.getItem("gallery-collapsed-sections") || "[]",
      )
    } catch {
      collapsed = []
    }

    for (const details of this.disclosures) {
      const label = this.sectionLabel(details)
      const holdsCurrent = Boolean(details.querySelector("[aria-current]"))
      details.open = holdsCurrent || !collapsed.includes(label)
    }
  }

  rememberSections = () => {
    const collapsed = this.disclosures
      .filter((details) => !details.open)
      .map((details) => this.sectionLabel(details))

    try {
      sessionStorage.setItem(
        "gallery-collapsed-sections",
        JSON.stringify(collapsed),
      )
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
