# frozen_string_literal: true

module NitroKit
  class AppearanceBootstrap < Phlex::HTML
    PREFERENCES = %i[light dark system].freeze
    STORAGE_KEY = "nitro-kit-appearance"

    SCRIPT = <<~JAVASCRIPT.freeze
      (() => {
        const preferences = ["light", "dark", "system"]
        const storageKey = "nitro-kit-appearance"
        const requestEvent = "nitro-kit:appearance-request"
        const changeEvent = "nitro-kit:appearance-change"
        const runtimeKey = Symbol.for("nitro-kit.appearance")
        const suppliedDefault = document.currentScript?.dataset.nkAppearanceDefault
        const valid = (value) => preferences.includes(value)
        const initialDefault = valid(suppliedDefault) ? suppliedDefault : "system"
        const existingRuntime = window[runtimeKey]

        if (existingRuntime) {
          existingRuntime.start(initialDefault)
          return
        }

        const root = document.documentElement
        const system = window.matchMedia("(prefers-color-scheme: dark)")
        let defaultPreference = initialDefault
        let preference = initialDefault
        let mediaListening = false
        let started = false

        const read = () => {
          try {
            const stored = window.localStorage.getItem(storageKey)
            return valid(stored) ? stored : defaultPreference
          } catch (_error) {
            return defaultPreference
          }
        }

        const write = (value) => {
          try {
            window.localStorage.setItem(storageKey, value)
          } catch (_error) {
            // The in-document preference still works when storage is unavailable.
          }
        }

        const resolve = () => {
          if (preference !== "system") return preference
          return system.matches ? "dark" : "light"
        }

        const broadcast = (theme) => {
          window.dispatchEvent(new CustomEvent(changeEvent, {
            detail: { preference, theme }
          }))
        }

        const reflect = () => {
          const theme = resolve()
          const changed = root.dataset.themePreference !== preference || root.dataset.theme !== theme

          root.dataset.themePreference = preference
          root.dataset.theme = theme
          if (changed) broadcast(theme)
        }

        const handleMediaChange = () => reflect()

        const synchronizeMediaListener = () => {
          if (preference === "system" && !mediaListening) {
            system.addEventListener("change", handleMediaChange)
            mediaListening = true
          } else if (preference !== "system" && mediaListening) {
            system.removeEventListener("change", handleMediaChange)
            mediaListening = false
          }
        }

        const apply = (nextPreference, persist = false) => {
          if (!valid(nextPreference)) return

          preference = nextPreference
          synchronizeMediaListener()
          if (persist) write(preference)
          reflect()
        }

        const handleRequest = (event) => {
          apply(event.detail?.preference, true)
        }

        const handleStorage = (event) => {
          if (event.key !== storageKey) return
          apply(valid(event.newValue) ? event.newValue : defaultPreference)
        }

        const runtime = {
          start(nextDefault) {
            if (valid(nextDefault)) defaultPreference = nextDefault

            if (!started) {
              window.addEventListener(requestEvent, handleRequest)
              window.addEventListener("storage", handleStorage)
              started = true
            }

            apply(read())
          }
        }

        window[runtimeKey] = runtime
        runtime.start(initialDefault)
      })()
    JAVASCRIPT

    CSP_HASH = "sha256-Vcime4euWSeYtHSfjYjqz/XhRyzMcLpn6Ip2LlaHleY="

    def initialize(default: :system, nonce: nil)
      @default = validate_default!(default)
      @nonce = validate_nonce!(nonce)
    end

    def view_template
      script(
        nonce: @nonce,
        data: { nk_appearance_default: @default }
      ) { raw safe(SCRIPT) }
    end

    private

    def validate_default!(value)
      return value if PREFERENCES.include?(value)

      raise ArgumentError, "Unknown appearance default #{value.inspect}; expected one of: :light, :dark, :system"
    end

    def validate_nonce!(value)
      return value if value.nil? || (value.is_a?(String) && !value.strip.empty?)

      raise ArgumentError, "AppearanceBootstrap nonce must be a non-blank String or nil"
    end
  end
end
