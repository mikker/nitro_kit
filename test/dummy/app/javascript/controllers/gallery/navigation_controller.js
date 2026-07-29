import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.sync()
  }

  rememberScroll() {
    this.element.galleryScrollTop = this.body.scrollTop
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
