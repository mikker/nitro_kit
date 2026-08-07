import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "track",
    "frame",
    "iframe",
    "handle",
    "range",
    "preset",
    "output",
    "reset",
    "full",
  ]

  static values = {
    min: { type: Number, default: 320 },
    constrained: { type: Number, default: 640 },
    step: { type: Number, default: 16 },
    sm: { type: Number, default: 640 },
    md: { type: Number, default: 768 },
    lg: { type: Number, default: 1024 },
    xl: { type: Number, default: 1280 },
    xxl: { type: Number, default: 1536 },
  }

  connect() {
    this.width = null
    this.requestedWidth = null
    this.maximum = 0
    this.fullWidth = this.element.dataset.galleryPreviewMode === "full-width"
    this.pointerId = null
    this.trackObserver = new ResizeObserver(() => this.measure())
    this.trackObserver.observe(this.trackTarget)
    this.visibilityObserver = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) this.measure()
    })
    this.visibilityObserver.observe(this.element)
    this.measure()
  }

  disconnect() {
    this.trackObserver?.disconnect()
    this.visibilityObserver?.disconnect()
    this.documentObserver?.disconnect()
    cancelAnimationFrame(this.heightFrame)
    this.releasePointer()
  }

  loaded() {
    this.documentObserver?.disconnect()

    const previewWindow = this.iframeTarget.contentWindow
    const previewBody = this.iframeTarget.contentDocument?.body
    if (!previewWindow || !previewBody) return

    this.documentObserver = new previewWindow.ResizeObserver(() => this.scheduleHeight())
    this.documentObserver.observe(previewBody)
    this.scheduleHeight()
  }

  resizeFromRange() {
    this.setWidth(Number(this.rangeTarget.value))
  }

  choosePreset() {
    if (!this.presetTarget.value) return

    this.setWidth(Number(this.presetTarget.value))
  }

  reset() {
    this.fullWidth = this.element.dataset.galleryPreviewMode === "full-width"
    this.setWidth(this.defaultWidth(), { preserveFullWidth: true })
    this.requestedWidth = null
    this.presetTarget.value = ""
  }

  full() {
    this.fullWidth = true
    this.setWidth(this.maximum, { preserveFullWidth: true })
    this.presetTarget.value = ""
  }

  startDrag(event) {
    if (!event.isPrimary || event.button !== 0) return

    event.preventDefault()
    this.pointerId = event.pointerId
    this.handleTarget.setPointerCapture(event.pointerId)
    this.resizeFromPointer(event)
  }

  drag(event) {
    if (event.pointerId !== this.pointerId) return

    this.resizeFromPointer(event)
  }

  stopDrag(event) {
    if (event.pointerId !== this.pointerId) return

    this.releasePointer()
  }

  resizeWithKeyboard(event) {
    const amount = event.shiftKey ? this.stepValue * 4 : this.stepValue
    const widths = {
      ArrowLeft: this.width - amount,
      ArrowRight: this.width + amount,
      Home: this.minimum,
      End: this.maximum,
    }
    if (!(event.key in widths)) return

    event.preventDefault()
    this.setWidth(widths[event.key])
  }

  measure() {
    const maximum = Math.floor(this.trackTarget.getBoundingClientRect().width)
    if (maximum < 1) return

    this.maximum = maximum
    this.minimum = Math.min(this.minValue, maximum)

    if (this.width === null) {
      this.width = this.defaultWidth()
    } else if (this.fullWidth) {
      this.width = maximum
    } else {
      this.width = this.clamp(this.requestedWidth ?? this.constrainedValue)
    }

    this.renderWidth()
  }

  defaultWidth() {
    if (this.element.dataset.galleryPreviewMode === "full-width") return this.maximum

    return this.clamp(this.constrainedValue)
  }

  setWidth(width, { preserveFullWidth = false } = {}) {
    this.requestedWidth = Math.round(width)
    this.width = this.clamp(this.requestedWidth)
    if (!preserveFullWidth) this.fullWidth = this.width === this.maximum
    this.renderWidth()
  }

  resizeFromPointer(event) {
    const track = this.trackTarget.getBoundingClientRect()
    this.setWidth(event.clientX - track.left)
  }

  releasePointer() {
    if (this.pointerId === null) return

    if (this.handleTarget.hasPointerCapture(this.pointerId)) {
      this.handleTarget.releasePointerCapture(this.pointerId)
    }
    this.pointerId = null
  }

  clamp(width) {
    return Math.min(this.maximum, Math.max(this.minimum, width))
  }

  renderWidth() {
    if (!this.maximum) return

    this.element.style.setProperty("--gallery-preview-width", `${this.width}px`)
    this.rangeTarget.min = this.minimum
    this.rangeTarget.max = this.maximum
    this.rangeTarget.value = this.width
    this.rangeTarget.disabled = this.minimum === this.maximum

    const breakpoint = this.activeBreakpoint()
    const valueText = `${this.width} pixels, ${breakpoint} breakpoint`
    this.outputTarget.textContent = `${this.width} px · ${breakpoint}${this.fullWidth ? " · full" : ""}`
    this.handleTarget.setAttribute("aria-valuemin", this.minimum)
    this.handleTarget.setAttribute("aria-valuemax", this.maximum)
    this.handleTarget.setAttribute("aria-valuenow", this.width)
    this.handleTarget.setAttribute("aria-valuetext", valueText)
    this.resetTarget.disabled = this.width === this.defaultWidth()
    this.fullTarget.disabled = this.width === this.maximum

    for (const option of this.presetTarget.options) {
      if (!option.value) continue

      option.disabled = Number(option.value) < this.minimum || Number(option.value) > this.maximum
    }
    if (this.presetTarget.selectedOptions[0]?.disabled) this.presetTarget.value = ""

    this.scheduleHeight()
  }

  activeBreakpoint() {
    let active = "base"

    const breakpoints = {
      sm: this.smValue,
      md: this.mdValue,
      lg: this.lgValue,
      xl: this.xlValue,
      "2xl": this.xxlValue,
    }

    for (const [name, width] of Object.entries(breakpoints)) {
      if (this.width >= width) active = name
    }

    return active
  }

  scheduleHeight() {
    cancelAnimationFrame(this.heightFrame)
    this.heightFrame = requestAnimationFrame(() => this.resizeHeight())
  }

  resizeHeight() {
    const previewBody = this.iframeTarget.contentDocument?.body
    if (!previewBody) return

    const height = Math.min(768, Math.max(192, Math.ceil(previewBody.scrollHeight)))
    this.iframeTarget.style.blockSize = `${height}px`
  }
}
