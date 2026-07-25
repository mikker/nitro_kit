import { Controller } from "@hotwired/stimulus"

const DARK_MEDIA_QUERY = "(prefers-color-scheme: dark)"
const PREVIEW_SELECTOR = '[data-gallery="theme-preview"]'

export default class extends Controller {
  static targets = [
    "form",
    "preview",
    "previewStyle",
    "cssOutput",
    "rubyOutput",
    "status",
    "errors",
    "shell"
  ]

  static values = { schema: Object }

  connect() {
    this.connected = true
    this.copyAttempt ||= 0
    this.copyTimer = null
    this.mediaQuery = window.matchMedia(DARK_MEDIA_QUERY)
    this.onSystemAppearanceChange = this.systemAppearanceChanged.bind(this)
    this.addMediaListener()

    const parsed = this.readUrl()
    this.applyPreset(parsed.preset)
    this.render(parsed.preset)
    this.showErrors(parsed.errors)
  }

  disconnect() {
    this.connected = false
    this.copyAttempt += 1
    this.removeMediaListener()
    window.clearTimeout(this.copyTimer)
  }

  change(event) {
    const preset = this.readForm()

    this.render(preset)
    this.showErrors([])

    if (event.target.name !== "appearance") this.replaceUrl(preset)
  }

  restore() {
    const parsed = this.readUrl()

    this.applyPreset(parsed.preset)
    this.render(parsed.preset)
    this.showErrors(parsed.errors)
  }

  reset(event) {
    event.preventDefault()

    const preset = { ...this.schemaValue.defaults }
    this.applyPreset(preset)
    this.setChecked("appearance", "system")
    this.render(preset)
    this.replaceUrl(preset)
    this.showErrors([])
    this.announce("Version 1 defaults restored.", "success", ++this.copyAttempt)
  }

  async copy(event) {
    event.preventDefault()
    const attempt = ++this.copyAttempt

    const kind = event.currentTarget.dataset.copyKind
    let source
    let label

    if (kind === "css") {
      source = this.cssOutputTarget.textContent
      label = "CSS"
    } else if (kind === "ruby") {
      source = this.rubyOutputTarget.textContent
      label = "AppShell Ruby"
    } else if (kind === "url") {
      const preset = this.readForm()
      this.replaceUrl(preset)
      source = window.location.href
      label = "Share link"
    } else {
      this.announce("Nothing was copied.", "error", attempt)
      return
    }

    try {
      if (!navigator.clipboard?.writeText) throw new Error("Clipboard unavailable")

      await navigator.clipboard.writeText(source)
      this.announce(`${label} copied.`, "success", attempt)
    } catch (_error) {
      this.announce(`${label} could not be copied.`, "error", attempt)
    }
  }

  systemAppearanceChanged() {
    if (this.previewAppearance() === "system") this.applyPreviewAppearance()
  }

  render(preset) {
    const css = this.cssFor(preset)

    this.previewStyleTarget.textContent = this.previewCssFor(preset)
    this.cssOutputTarget.textContent = css
    this.rubyOutputTarget.textContent = this.schemaValue.shellExamples[preset.shell]
    this.shellTarget.dataset.variant = preset.shell
    this.previewTarget.dataset.preset = this.queryFor(preset)
    this.applyPreviewAppearance()
  }

  readUrl() {
    const parameters = new URL(window.location.href).searchParams
    const versionValues = parameters.getAll("v")

    if (versionValues.length > 0 && (
      versionValues.length !== 1 || versionValues[0] !== String(this.schemaValue.version)
    )) {
      return {
        preset: { ...this.schemaValue.defaults },
        errors: [ `This preset version is not supported. Version ${this.schemaValue.version} defaults were restored.` ]
      }
    }

    const errors = []
    const preset = {}

    for (const attribute of this.schemaValue.attributes) {
      const values = parameters.getAll(attribute)
      const value = values[0]

      if (values.length === 0) {
        preset[attribute] = this.schemaValue.defaults[attribute]
      } else if (values.length === 1 && this.schemaValue.choices[attribute].includes(value)) {
        preset[attribute] = value
      } else {
        preset[attribute] = this.schemaValue.defaults[attribute]
        errors.push(`${this.humanize(attribute)} is not supported. The default was restored.`)
      }
    }

    return { preset, errors }
  }

  readForm() {
    return Object.fromEntries(
      this.schemaValue.attributes.map((attribute) => {
        const value = this.checkedValue(attribute)
        const valid = this.schemaValue.choices[attribute].includes(value)

        return [ attribute, valid ? value : this.schemaValue.defaults[attribute] ]
      })
    )
  }

  applyPreset(preset) {
    for (const attribute of this.schemaValue.attributes) {
      this.setChecked(attribute, preset[attribute])
    }
  }

  checkedValue(name) {
    const controls = Array.from(this.formTarget.elements).filter((control) => control.name === name)
    return controls.find((control) => control.checked)?.value
  }

  setChecked(name, value) {
    for (const control of this.formTarget.elements) {
      if (control.name === name) control.checked = control.value === value
    }
  }

  previewAppearance() {
    const appearance = this.checkedValue("appearance")
    return [ "light", "dark", "system" ].includes(appearance) ? appearance : "system"
  }

  applyPreviewAppearance() {
    const appearance = this.previewAppearance()
    const resolved = appearance === "system"
      ? (this.mediaQuery.matches ? "dark" : "light")
      : appearance

    this.previewTarget.dataset.previewAppearance = appearance
    this.previewTarget.dataset.theme = resolved
  }

  replaceUrl(preset) {
    const url = new URL(window.location.href)
    const owned = new Set([ ...this.schemaValue.parameterOrder, "appearance" ])
    const preserved = Array.from(url.searchParams.entries()).filter(([ name ]) => !owned.has(name))

    url.search = ""
    for (const name of this.schemaValue.parameterOrder) {
      const value = name === "v" ? String(this.schemaValue.version) : preset[name]
      url.searchParams.append(name, value)
    }
    for (const [ name, value ] of preserved) url.searchParams.append(name, value)

    window.history.replaceState(window.history.state, "", url)
  }

  queryFor(preset) {
    const parameters = new URLSearchParams()

    for (const name of this.schemaValue.parameterOrder) {
      const value = name === "v" ? String(this.schemaValue.version) : preset[name]
      parameters.append(name, value)
    }

    return parameters.toString()
  }

  cssFor(preset) {
    const lightTokens = this.exportTokens(preset, "light")
    const darkTokens = this.exportTokens(preset, "dark")

    return [
      this.cssBlock(':root, [data-theme="light"]', lightTokens),
      this.systemCssBlock(darkTokens),
      this.cssBlock('[data-theme="dark"]', darkTokens)
    ].join("\n\n")
  }

  previewCssFor(preset) {
    return [
      this.cssBlock(PREVIEW_SELECTOR, this.previewTokens(preset, "light")),
      this.cssBlock(`${PREVIEW_SELECTOR}[data-theme="dark"]`, this.previewTokens(preset, "dark"))
    ].join("\n\n")
  }

  exportTokens(preset, appearance) {
    if (appearance === "light") {
      const tokens = { ...this.sharedTokens(preset), ...this.appearanceTokens(preset, "light") }
      const baseline = {
        ...this.schemaValue.baselines.shared,
        ...this.schemaValue.baselines.light
      }

      return this.changedTokens(tokens, baseline)
    }

    const tokens = this.appearanceTokens(preset, "dark")
    const lightChanges = new Set(
      Object.keys(this.changedTokens(
        this.appearanceTokens(preset, "light"),
        this.schemaValue.baselines.light
      ))
    )

    return this.sortedObject(
      Object.fromEntries(
        Object.entries(tokens).filter(([ name, value ]) => (
          this.schemaValue.baselines.dark[name] !== value || lightChanges.has(name)
        ))
      )
    )
  }

  previewTokens(preset, appearance) {
    return this.sortedObject({
      ...this.sharedTokens(preset),
      ...this.appearanceTokens(preset, appearance)
    })
  }

  sharedTokens(preset) {
    return [ "radius", "density", "font" ].reduce((tokens, attribute) => ({
      ...tokens,
      ...this.schemaValue.tokenMaps[attribute][preset[attribute]].shared
    }), {})
  }

  appearanceTokens(preset, appearance) {
    return [ "neutral", "accent" ].reduce((tokens, attribute) => ({
      ...tokens,
      ...this.schemaValue.tokenMaps[attribute][preset[attribute]][appearance]
    }), {})
  }

  changedTokens(tokens, baseline) {
    return this.sortedObject(
      Object.fromEntries(
        Object.entries(tokens).filter(([ name, value ]) => baseline[name] !== value)
      )
    )
  }

  sortedObject(object) {
    return Object.fromEntries(Object.entries(object).sort(([ left ], [ right ]) => {
      if (left < right) return -1
      if (left > right) return 1
      return 0
    }))
  }

  cssBlock(selector, tokens) {
    const declarations = Object.entries(tokens).map(([ name, value ]) => `  ${name}: ${value};`)
    return [ `${selector} {`, ...declarations, "}" ].join("\n")
  }

  systemCssBlock(tokens) {
    const declarations = Object.entries(tokens).map(([ name, value ]) => `    ${name}: ${value};`)
    return [
      `@media ${DARK_MEDIA_QUERY} {`,
      '  :root:not([data-theme]) {',
      ...declarations,
      "  }",
      "}"
    ].join("\n")
  }

  showErrors(errors) {
    this.errorsTarget.hidden = errors.length === 0
    this.errorsTarget.textContent = errors.join(" ")
  }

  announce(message, state, attempt) {
    if (!this.connected || attempt !== this.copyAttempt) return

    window.clearTimeout(this.copyTimer)
    this.statusTarget.textContent = message
    this.statusTarget.dataset.state = state
    this.copyTimer = window.setTimeout(() => {
      if (!this.connected || attempt !== this.copyAttempt) return

      this.statusTarget.textContent = ""
      delete this.statusTarget.dataset.state
    }, 4000)
  }

  addMediaListener() {
    if (this.mediaQuery.addEventListener) {
      this.mediaQuery.addEventListener("change", this.onSystemAppearanceChange)
    } else {
      this.mediaQuery.addListener(this.onSystemAppearanceChange)
    }
  }

  removeMediaListener() {
    if (!this.mediaQuery) return

    if (this.mediaQuery.removeEventListener) {
      this.mediaQuery.removeEventListener("change", this.onSystemAppearanceChange)
    } else {
      this.mediaQuery.removeListener(this.onSystemAppearanceChange)
    }
  }

  humanize(value) {
    return value.replaceAll("_", " ").replace(/^./, (character) => character.toUpperCase())
  }
}
