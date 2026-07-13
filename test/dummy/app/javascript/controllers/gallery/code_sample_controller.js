import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "status"]
  static values = { resetAfter: { type: Number, default: 2000 } }

  connect() {
    this.connected = true
    this.copyAttempt ||= 0
  }

  disconnect() {
    this.connected = false
    this.copyAttempt += 1
    clearTimeout(this.resetTimer)
  }

  async copy(event) {
    event.preventDefault()
    const attempt = ++this.copyAttempt

    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent)
      this.#announce("Copied to clipboard", attempt)
    } catch {
      this.#announce("Could not copy", attempt)
    }
  }

  #announce(message, attempt) {
    if (!this.connected || attempt !== this.copyAttempt) return

    clearTimeout(this.resetTimer)
    this.statusTarget.textContent = message
    this.element.dataset.galleryCodeState = message === "Copied to clipboard" ? "copied" : "error"

    this.resetTimer = setTimeout(() => {
      if (!this.connected || attempt !== this.copyAttempt) return

      this.statusTarget.textContent = ""
      delete this.element.dataset.galleryCodeState
    }, this.resetAfterValue)
  }
}
