require "application_system_test_case"

# Loads every gallery example flagged `stress: true` in its isolated preview at
# phone, tablet, and desktop widths and runs the layout audit in
# test/system/support/layout_audit.js against it. The audit is geometric, so
# one theme is enough; the theme tests prove light and dark separately.
#
# Stress examples compose from Gallery::Hostile. One test per catalog entry
# keeps failures attributable to a component; a test reports every violation
# it found rather than stopping at the first.
class StressSweepTest < ApplicationSystemTestCase
  Viewport = Data.define(:name, :width, :height)

  VIEWPORTS = [
    Viewport.new(name: "phone", width: 390, height: 844),
    Viewport.new(name: "tablet", width: 768, height: 1024),
    Viewport.new(name: "desktop", width: 1440, height: 1000)
  ].freeze

  # Capybara prefixes evaluated scripts with `return`, so the leading comment
  # lines are dropped to keep the function expression on the same line.
  AUDIT_SOURCE = File.read(File.expand_path("support/layout_audit.js", __dir__))
    .lines.reject { |line| line.start_with?("//") }.join.strip.delete_suffix(";").freeze

  # Entries that still break under hostile content because of an open design
  # decision, not a slot bug. Each is reported as a skip with its reason, and
  # the test fails if a listed entry comes back clean so the list stays honest.
  KNOWN_BREAKAGE = {
    "app-shell" => "Button labels never wrap or truncate, so a long topbar action is clipped by the shell.",
    "control-group" => "Addons and Button labels keep their full width, so a long prefix or label pushes the group past the viewport.",
    "empty-state" => "Button labels never wrap or truncate, so a long action overflows a narrow empty state.",
    "pagination" => "The item list neither wraps nor scrolls, so many pages or long labels run past the viewport."
  }.freeze

  setup { skip "Chrome DevTools emulation coverage" unless chrome? }

  Gallery::Catalog.entries.reject { |entry| entry.kind == :home }.each do |entry|
    test "#{entry.kind} #{entry.slug} survives hostile content" do
      previews = stress_previews(entry)
      skip "#{entry.slug} declares no stress examples" if previews.empty?

      violations = previews.flat_map do |preview|
        VIEWPORTS.flat_map { |viewport| audit(preview, viewport) }
      end

      if (reason = KNOWN_BREAKAGE[entry.slug])
        assert violations.any?, "#{entry.slug} is listed in KNOWN_BREAKAGE but passed; remove it from the list"
        skip "known breakage (#{violations.size} violations): #{reason}"
      end

      assert violations.empty?, report(entry, violations)
    end
  end

  private

  Violation = Data.define(:preview, :viewport, :rule, :element, :detail, :text)

  def stress_previews(entry)
    self.class.all_stress_previews.select { |preview| preview.entry == entry }
  end

  # Enumerating renders every page once, so the list is shared across tests.
  def self.all_stress_previews
    @all_stress_previews ||= Gallery::Catalog.stress_previews
  end

  def preview_path(preview)
    gallery_preview_path(
      kind: preview.entry.kind,
      slug: preview.entry.slug,
      example: preview.example,
      state: preview.state,
      theme: "light"
    )
  end

  def audit(preview, viewport)
    emulate_viewport(viewport)
    visit preview_path(preview)
    assert_selector "main[data-gallery-responsive-preview='true'] [data-gallery='example-canvas']"
    assert_no_severe_console_errors(context: "#{preview_path(preview)} at #{viewport.name}")

    result = evaluate_script("#{AUDIT_SOURCE}({})")
    raise "layout audit did not return an Array (got #{result.class}); check that the script evaluates to a call" unless result.is_a?(Array)

    result.map do |violation|
      Violation.new(
        preview: preview.example,
        viewport: viewport.name,
        rule: violation.fetch("rule"),
        element: violation.fetch("element"),
        detail: violation.fetch("detail"),
        text: violation["text"]
      )
    end
  end

  # Chrome refuses windows narrower than about 500px, so the phone width is
  # emulated through DevTools on top of the resized window.
  def emulate_viewport(viewport)
    resize_viewport(width: viewport.width, height: viewport.height)
    browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: viewport.width,
      height: viewport.height,
      deviceScaleFactor: 1,
      mobile: false
    )
  end

  def report(entry, violations)
    lines = violations.group_by { |violation| [ violation.preview, violation.viewport ] }.map do |(preview, viewport), group|
      body = group.map do |violation|
        line = "    #{violation.rule}: #{violation.element} — #{violation.detail}"
        line += " (#{violation.text.inspect})" if violation.text.present?
        line
      end
      "  #{preview} @ #{viewport}\n#{body.join("\n")}"
    end

    "#{entry.kind} #{entry.slug}: #{violations.size} layout violation(s) under hostile content\n#{lines.join("\n")}"
  end
end
