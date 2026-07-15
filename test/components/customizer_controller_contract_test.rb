require "test_helper"

class CustomizerControllerContractTest < ActiveSupport::TestCase
  CONTROLLER = NitroKit::Engine.root.join(
    "test/dummy/app/javascript/controllers/gallery/customizer_controller.js"
  )

  test "reacts from server-owned schema without constructing markup" do
    source = CONTROLLER.read

    assert_includes source, "static values = { schema: Object }"
    assert_includes source, "this.schemaValue.choices"
    assert_includes source, "this.schemaValue.tokenMaps"
    assert_includes source, "this.schemaValue.baselines"
    assert_includes source, "this.schemaValue.shellExamples[preset.shell]"
    assert_includes source, "this.previewStyleTarget.textContent"
    assert_includes source, "this.cssOutputTarget.textContent"
    assert_includes source, "this.rubyOutputTarget.textContent"
    refute_includes source, "innerHTML"
    refute_includes source, "insertAdjacentHTML"
    refute_includes source, "createElement"
    refute_includes source, "eval("
  end

  test "keeps readable URL edits and restoration explicit" do
    source = CONTROLLER.read

    assert_includes source, "new URL(window.location.href).searchParams"
    assert_includes source, 'parameters.getAll("v")'
    assert_includes source, "this.schemaValue.parameterOrder"
    assert_includes source, "window.history.replaceState(window.history.state"
    assert_includes source, '[ ...this.schemaValue.parameterOrder, "appearance" ]'
    assert_includes source, "restore()"
    assert_includes source, "this.applyPreset(parsed.preset)"
    refute_includes source, "pushState"
    refute_includes source, "btoa"
    refute_includes source, "atob"
  end

  test "isolates preview appearance and cleans retained resources" do
    source = CONTROLLER.read

    assert_includes source, "window.matchMedia(DARK_MEDIA_QUERY)"
    assert_includes source, 'addEventListener("change", this.onSystemAppearanceChange)'
    assert_includes source, 'removeEventListener("change", this.onSystemAppearanceChange)'
    assert_includes source, "this.previewTarget.dataset.theme = resolved"
    assert_includes source, "this.previewTarget.dataset.previewAppearance = appearance"
    assert_includes source, "window.clearTimeout(this.copyTimer)"
    refute_includes source, "localStorage"
    refute_includes source, "sessionStorage"
    refute_includes source, "document.documentElement"
    refute_includes source, "nitro-kit:appearance"
    refute_includes source, "dispatchEvent"
  end

  test "guards asynchronous clipboard announcements by connection and revision" do
    source = CONTROLLER.read

    assert_includes source, "const attempt = ++this.copyAttempt"
    assert_includes source, "this.copyAttempt += 1"
    assert_includes source, "attempt !== this.copyAttempt"
    assert_includes source, "navigator.clipboard?.writeText"
    assert_includes source, "await navigator.clipboard.writeText(source)"
    assert_includes source, "this.statusTarget.textContent = message"
    assert_includes source, "if (!this.connected || attempt !== this.copyAttempt) return"
  end

  test "generates ordered light system and explicit dark CSS from public maps" do
    source = CONTROLLER.read

    assert_includes source, "this.cssBlock(':root, [data-theme=\"light\"]', lightTokens)"
    assert_includes source, "this.systemCssBlock(darkTokens)"
    assert_includes source, "this.cssBlock('[data-theme=\"dark\"]', darkTokens)"
    assert_includes source, "lightChanges.has(name)"
    assert_includes source, "Object.entries(object).sort"
    assert_includes source, "left < right"
    refute_includes source, "--_nk-"
  end
end
