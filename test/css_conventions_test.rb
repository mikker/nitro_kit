require "test_helper"

load File.expand_path("../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

# System-wide CSS conventions.
#
# The per-component `*_css_test.rb` files pin each component's own declarations,
# which is where a component's individual contract belongs. These rules cover the
# cross-cutting question no single component is positioned to answer: whether a
# value belongs to the shared design system at all.
#
# Each rule reports offenders as `{ "file.css" => [values] }` and compares that
# against KNOWN_VIOLATIONS with an exact match. Exact match is deliberate: fixing
# a violation fails this test until its allowlist entry is removed, so the
# allowlist can only be drained on purpose. Entries key on value rather than line
# number so unrelated edits above them do not churn the list.
class CssConventionsTest < ActiveSupport::TestCase
  # `--nk-space` multipliers the design system actually defines. Mirrors
  # NitroKit::LayoutOptions::GAPS, plus 0.5 for hairline insets.
  SPACING_STEPS = [ 0.5, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16 ].freeze

  # Fixed responsive breakpoints. Documented in STYLE_GUIDE.md as component API
  # rather than themeable tokens, so they are legitimately literal.
  BREAKPOINTS = %w[40rem 48rem 64rem 80rem 96rem].freeze

  # Spellings the destructive semantic could take.
  DESTRUCTIVE_SPELLINGS = %w[danger destructive error].freeze

  # What it is spelled today. Button and Dropdown say `destructive`, Alert and
  # Toast say `error`, and the tokens say `danger`. Target is `%w[danger]`, which
  # matches the token layer and needs no CSS rename.
  DESTRUCTIVE_SPELLINGS_IN_USE = %w[destructive error].freeze

  RULES = %i[
    spacing_scale literal_lengths font_size box_shadow opacity reduced_motion
    hover_guard
  ].freeze

  # Every violation present when these rules were introduced, so the rules land
  # green and block new drift immediately. Each batch of the consistency work
  # drains its own entries. The goal is an empty hash and the deletion of this
  # constant.
  KNOWN_VIOLATIONS = {
    # Off-scale `--nk-space` multipliers.
    spacing_scale: {
      "avatar_stack.css" => [ "-1.5" ],
      "badge.css" => [ "1.25", "1.5" ],
      "button.css" => [ "7" ],
      "command_palette.css" => [ "1.5" ],
      "rich_text_area.css" => [ "24" ],
      "select.css" => [ "9" ],
      "table.css" => [ "1.5" ],
      "tooltip.css" => [ "1.5", "2.5" ]
    },
    # Literal geometry that should be a token. The `1px` entries are hairline
    # borders and visually-hidden clip rectangles; the `rem` entries are control,
    # icon, avatar and overlay sizes.
    literal_lengths: {
      "accordion.css" => [ "1rem", "1rem", "2.75rem" ],
      "alert.css" => [ "0.0625rem", "1.25rem", "1.25rem" ],
      "app_shell.css" => [ "-1px", "1px", "1px" ],
      "appearance_picker.css" => [ "1.125rem", "1.125rem" ],
      "avatar.css" => [ "1.5rem", "2rem", "3rem", "4rem" ],
      "avatar_stack.css" => [ "1.5rem", "1.5rem", "2rem", "2rem", "3rem", "3rem", "4rem", "4rem" ],
      "button.css" => [ "1.25rem", "1.25rem", "1.5rem", "1.5rem", "1.75rem", "1px", "1px", "1px", "1rem", "1rem", "2px", "2px", "2rem" ],
      "checkbox.css" => [ "-0.0625rem", "0.125rem", "0.125rem", "0.125rem", "0.375rem", "0.3rem", "0.55rem", "0.5rem", "0.625rem", "0.7rem", "1.125rem", "1.125rem", "1.125rem", "1.125rem", "1.5rem", "1.5rem", "1.5rem", "1.5rem" ],
      "combobox.css" => [ "-0.25rem", "-1px", "12rem", "12rem", "15rem", "1px", "1px", "28rem" ],
      "command_palette.css" => [ "-0.5rem", "-1px", "1px", "1px", "26rem", "36rem" ],
      "details_table.css" => [ "16rem", "8rem" ],
      "dialog.css" => [ "0.5rem" ],
      "dropdown.css" => [ "-0.25rem", "12rem", "24rem", "24rem" ],
      "dropzone.css" => [ "16rem", "1px", "1px", "1px", "1px", "1px", "1px", "24rem", "3rem", "3rem" ],
      "empty_state.css" => [ "2rem", "2rem" ],
      "icon.css" => [ "0.75rem", "1.25rem", "1.75rem", "1rem", "2.25rem" ],
      "input.css" => [ "1.125rem", "1.125rem" ],
      "pagination.css" => [ "-1px", "1px", "1px" ],
      "progressive_image.css" => [ "10rem", "1rem" ],
      "radio_button.css" => [ "0.5rem", "0.5rem", "1.125rem", "1.125rem", "1.125rem", "1.125rem", "1.5rem", "1.5rem", "1.5rem", "1.5rem" ],
      "select.css" => [ "10rem", "1rem", "1rem" ],
      "settings_layout.css" => [ "10rem", "14rem" ],
      "settings_section.css" => [ "10rem", "14rem" ],
      "sheet.css" => [ "-1rem", "-1rem", "1rem", "1rem", "20rem", "28rem", "40rem" ],
      "switch.css" => [ "0.1875rem", "1.25rem", "1.5rem", "1.5rem", "1.5rem", "1.5rem", "1rem", "1rem", "1rem", "2.5rem", "2.5rem", "2.5rem", "2rem", "3.25rem", "3.25rem" ],
      "table.css" => [ "40px" ],
      "textarea.css" => [ "6rem" ],
      "toast.css" => [ "26rem" ],
      "tooltip.css" => [ "20rem" ]
    },
    # Avatar initials invent steps below `--nk-text-xs`.
    font_size: {
      "avatar.css" => [ "calc(var(--nk-text-xs) * 0.875)" ],
      "avatar_stack.css" => [ "calc(var(--nk-text-xs) * 0.875)" ],
      "button.css" => [ "calc(var(--nk-text-xs) * 0.75)", "calc(var(--nk-text-xs) * 0.875)", "calc(var(--nk-text-xs) * 0.875)" ]
    },
    # Button builds its own elevation instead of using the shadow scale.
    box_shadow: {
      "button.css" => [ "0 1px 2px 0 oklch(0 0 0 / 0.05)", "inset 0 1px oklch(1 0 0 / 0.2)", "inset 0 1px var(--nk-color-danger), inset 0 2px oklch(1 0 0 / 0.15)" ]
    },
    # Four different disabled treatments. `0.6` is the de facto standard.
    opacity: {
      "button.css" => [ "0.75" ],
      "checkbox.css" => [ "0.6" ],
      "combobox.css" => [ "0.6" ],
      "dropdown.css" => [ "0.6" ],
      "dropzone.css" => [ "0.6" ],
      "input.css" => [ "0.6" ],
      "radio_button.css" => [ "0.6" ],
      "select.css" => [ "0.6" ],
      "switch.css" => [ "0.6" ],
      "table.css" => [ "0.5" ],
      "tabs.css" => [ "0.55" ],
      "textarea.css" => [ "0.6" ]
    },
    # Transitions with no reduced-motion guard.
    reduced_motion: {
      "checkbox.css" => [ "unguarded" ],
      "input.css" => [ "unguarded" ],
      "select.css" => [ "unguarded" ],
      "textarea.css" => [ "unguarded" ]
    },
    hover_guard: {
      "details_table.css" => [ "unguarded" ]
    }
  }.freeze

  test "spacing derives from the --nk-space scale" do
    assert_convention :spacing_scale do |css|
      css.scan(/var\(--nk-space\)\s*\*\s*(-?[\d.]+)/).flatten.reject do |step|
        SPACING_STEPS.include?(step.to_f.abs)
      end
    end
  end

  test "component geometry uses tokens rather than literal lengths" do
    assert_convention :literal_lengths do |css|
      without_media_preludes(css).scan(/(?<![\w-])(-?[\d.]+(?:rem|px))/).flatten
    end
  end

  test "font sizes come from the type scale" do
    assert_convention :font_size do |css|
      declared_values(css, "font-size").reject { |value| on_type_scale?(value) }
    end
  end

  test "shadows come from the shadow scale" do
    assert_convention :box_shadow do |css|
      declared_values(css, "box-shadow", stem: "shadow").reject { |value| on_shadow_scale?(value) }
    end
  end

  test "partial opacity is themeable rather than literal" do
    assert_convention :opacity do |css|
      declared_values(css, "opacity").select { |value| literal_partial_opacity?(value) }
    end
  end

  test "motion respects reduced-motion preferences" do
    assert_convention :reduced_motion do |css|
      animates?(css) && !css.include?("prefers-reduced-motion") ? [ "unguarded" ] : []
    end
  end

  test "hover treatments are guarded for touch pointers" do
    assert_convention :hover_guard do |css|
      css.include?(":hover") && !css.include?("hover: hover") ? [ "unguarded" ] : []
    end
  end

  test "the destructive semantic keeps one spelling" do
    assert_equal DESTRUCTIVE_SPELLINGS_IN_USE, destructive_spellings_in_use.sort, <<~MESSAGE
      The destructive semantic changed spelling.

      Unifying it? Narrow DESTRUCTIVE_SPELLINGS_IN_USE to %w[danger].
      Adding a component? Use the spelling already in use, not a new one.
    MESSAGE
  end

  test "the allowlist stays honest" do
    assert_empty KNOWN_VIOLATIONS.keys - RULES,
      "KNOWN_VIOLATIONS names a rule that does not exist, which silently disables it"

    KNOWN_VIOLATIONS.each_value do |files|
      assert_predicate files, :any?, "Empty rule entries should be deleted, not kept"

      files.each_value do |values|
        assert_predicate values, :any?, "Empty file entries should be deleted, not kept"
      end
    end
  end

  private

  def assert_convention(rule)
    offenders = NitroKit::CssBundle.component_sources.filter_map do |path|
      values = yield(path.read)
      [ path.basename.to_s, values.sort ] if values.any?
    end.to_h

    assert_equal KNOWN_VIOLATIONS.fetch(rule, {}), offenders, <<~MESSAGE
      #{rule} offenders changed.

      Fixed something? Remove its entry from KNOWN_VIOLATIONS[:#{rule}].
      Added something? Use a design system token instead.
    MESSAGE
  end

  # Values of a declaration, plus definitions of the private variables that feed
  # it, so indirection through `--_nk-*` cannot hide a literal. `stem` is how the
  # variable names the concept: `--_nk-button-shadow` backs `box-shadow`.
  def declared_values(css, property, stem: property)
    direct = css.scan(/(?<![\w-])#{property}:\s*([^;}]+)/m)
    indirect = css.scan(/--_nk-[\w-]*#{stem}[\w-]*:\s*([^;}]+)/m)

    (direct + indirect).flatten.map { |value| value.gsub(/\s+/, " ").strip }
  end

  # `em` is relative to the element's own type, so prose scaling is on-system.
  # Scaling a token by a bare factor is not: it invents a step between sizes.
  def on_type_scale?(value)
    return true if value == "inherit" || value.match?(/\A[\d.]+em\z/)

    !absolute_length?(value) && !scales_a_token?(value)
  end

  # A ring built entirely from tokens (`0 0 0 var(--nk-border-width) …`) is a
  # border treatment rather than elevation, so it does not belong to the shadow
  # scale. A literal length in a shadow does.
  def on_shadow_scale?(value)
    value == "none" || !absolute_length?(value)
  end

  def absolute_length?(value)
    value.match?(/(?<![\w-])[\d.]+(?:rem|px)/)
  end

  def scales_a_token?(value)
    value.match?(%r{var\([^)]*\)\s*[*/]|[*/]\s*var\(})
  end

  # 0 and 1 are structural (show/hide), not a themeable decision.
  def literal_partial_opacity?(value)
    value.match?(/\A[\d.]+\z/) && ![ 0.0, 1.0 ].include?(value.to_f)
  end

  def animates?(css)
    css.match?(/(?<![\w-])(transition|animation):/)
  end

  # Breakpoints are documented component API, so their literals are legitimate.
  def without_media_preludes(css)
    css.gsub(/@media[^{]*\{/) do |prelude|
      BREAKPOINTS.any? { |width| prelude.include?(width) } ? "" : prelude
    end
  end

  def destructive_spellings_in_use
    sources = NitroKit::CssBundle.component_sources.map(&:read) +
      NitroKit::Engine.root.glob("app/components/nitro_kit/*.rb").map(&:read)

    sources.flat_map { |source|
      source.scan(/data-variant="(\w+)"/).flatten +
        source.scan(/^\s*(?:ITEM_)?VARIANTS\s*=\s*%i\[([^\]]+)\]/).flatten.flat_map(&:split)
    }.uniq & DESTRUCTIVE_SPELLINGS
  end
end
