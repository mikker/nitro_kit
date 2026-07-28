import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.sync()
  }

  rememberScroll() {
    this.element.galleryScrollTop = this.body.scrollTop
  }

  visitSelection(event) {
    if (event.type === "keydown" && event.key !== "Enter") return
    if (
      event.type === "click" &&
      !event.target.closest('[data-slot="combobox-option"]')
    )
      return

    const combobox = event.currentTarget
    const select = combobox.querySelector(
      '[data-nk--combobox-target~="value"]',
    )
    const destination = select.value
    if (!destination) return

    const input = combobox.querySelector(
      '[data-nk--combobox-target~="input"]',
    )
    input.value = ""
    input.dispatchEvent(new Event("input", { bubbles: true }))
    window.Turbo.visit(destination)
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
