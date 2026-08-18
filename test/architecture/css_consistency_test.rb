require "test_helper"

# The stylesheet conventions from STYLE_GUIDE.md, asserted with no allowlist:
# every rule describes the current target state, so a failure is a regression,
# not a known exception.
class CssConsistencyTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root
  COMPONENTS = Dir[ROOT.join("src/stylesheets/nitro_kit/components/*.css")].sort.freeze
  RUBY_COMPONENTS = Dir[ROOT.join("app/components/nitro_kit/*.rb")].sort.freeze

  # The documented step set for --nk-space multipliers.
  SPACING_STEPS = [ 0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6, 7, 8, 10, 12, 16, 24 ].freeze

  # Breakpoints are documented component API, so their literals are legitimate.
  BREAKPOINTS = %w[40rem 48rem 64rem 80rem 96rem].freeze

  # The four documented z-index tiers: component parts, shell chrome, floating
  # overlays outside the top layer, and the system tier.
  Z_TIERS = [ 1, 2, 3, 10, 20, 30, 50, 100 ].freeze

  test "spacing multipliers stay on the documented step set" do
    assert_clean("spacing off the --nk-space scale") do |css|
      css.scan(/var\(--nk-space\)\s*\*\s*(-?[\d.]+)/).flatten
        .reject { |step| SPACING_STEPS.include?(step.to_f.abs) }
    end
  end

  test "owned geometry resolves through tokens, not literal lengths" do
    assert_clean("literal lengths in owned geometry") do |css|
      geometry_scope(css).scan(/(?<![\w-])(-?[\d.]+(?:rem|px))/).flatten
    end
  end

  test "font sizes come from the type scale" do
    assert_clean("font sizes off the type scale") do |css|
      declared_values(css, "font-size").reject do |value|
        value == "inherit" || value.match?(/\A[\d.]+em\z/) ||
          value.match?(/\Acalc\(var\(--nk-text-[\w-]+\)\s*\*\s*[\d.]+\)\z/) ||
          value.match?(/\Amin\(\s*var\(--nk-text-[\w-]+\)[^;}]*\)\z/) ||
          (!absolute_length?(value) && !scales_a_token?(value))
      end
    end
  end

  test "shadows come from the shadow scale" do
    assert_clean("shadows off the shadow scale") do |css|
      declared_values(css, "box-shadow", stem: "shadow").reject do |value|
        value == "none" || value.start_with?("inset") || !absolute_length?(value)
      end
    end
  end

  test "partial opacity is themeable" do
    assert_clean("raw partial opacity") do |css|
      declared_values(css, "opacity").select do |value|
        value.match?(/\A[\d.]+\z/) && ![ 0.0, 1.0 ].include?(value.to_f)
      end
    end
  end

  test "motion respects reduced-motion" do
    assert_clean("unguarded motion") do |css|
      if css.match?(/(?<![\w-])(transition|animation):/) && !css.include?("prefers-reduced-motion")
        [ "transition or animation without a prefers-reduced-motion guard" ]
      else
        []
      end
    end
  end

  test "hover is guarded for touch" do
    assert_clean("unguarded hover") do |css|
      if css.include?(":hover") && !css.include?("hover: hover")
        [ ":hover outside @media (hover: hover)" ]
      else
        []
      end
    end
  end

  test "z-index stays on the four documented tiers" do
    assert_clean("z-index off the documented tiers") do |css|
      css.scan(/z-index:\s*(-?\d+)/).flatten
        .reject { |value| Z_TIERS.include?(value.to_i) }
    end
  end

  test "the destructive semantic keeps its two spellings" do
    spellings = (COMPONENTS + RUBY_COMPONENTS).map { |path| File.read(path) }
      .flat_map { |source|
        source.scan(/data-variant="(\w+)"/).flatten +
          source.scan(/^\s*(?:ITEM_)?VARIANTS\s*=\s*%i\[([^\]]+)\]/).flatten.flat_map(&:split)
      }.uniq & %w[danger destructive error]

    assert_equal %w[destructive error], spellings.sort,
      "actions and Alert say destructive, Toast items say error, and danger is retired"
  end

  private

  def assert_clean(description, &rule)
    offenders = COMPONENTS.filter_map do |path|
      values = rule.call(File.read(path))
      "#{File.basename(path)}: #{values.sort.join(" ")}" if values.any?
    end

    assert_empty offenders, "#{description}:\n  #{offenders.join("\n  ")}"
  end

  # Values of a declaration plus the private variables that feed it, so
  # indirection through `--_nk-*` cannot hide a literal.
  def declared_values(css, property, stem: property)
    direct = css.scan(/(?<![\w-])#{property}:\s*([^;}]+)/m)
    indirect = css.scan(/--_nk-[\w-]*#{stem}[\w-]*:\s*([^;}]+)/m)
    (direct + indirect).flatten.map { |value| value.gsub(/\s+/, " ").strip }
  end

  def absolute_length?(value)
    value.match?(/(?<![\w-])[\d.]+(?:rem|px)/)
  end

  def scales_a_token?(value)
    value.match?(%r{var\([^)]*\)\s*[*/]|[*/]\s*var\(})
  end

  # What the geometry rule polices. Comments are prose; the visually-hidden
  # recipe pins 1px boxes by specification; shadow lengths belong to the
  # shadow rule; min/max constraints on panels and overlays are viewport
  # policy, not geometry that rides the token system; container-query and
  # breakpoint preludes are documented thresholds.
  def geometry_scope(css)
    css
      .gsub(%r{/\*.*?\*/}m, "")
      .gsub(/@media[^{]*\{/) do |prelude|
        BREAKPOINTS.any? { |width| prelude.include?(width) } ? "" : prelude
      end
      .gsub(/@container[^{]*\{/, "")
      .gsub(/\{[^{}]*(?:clip:\s*rect|clip-path:\s*inset\(50%\))[^{}]*\}/m, "{}")
      .gsub(/(?:box-shadow|--_nk-[\w-]*shadow):[^;}]+/m, "")
      .gsub(/(?:min|max)-(?:inline|block)-size:[^;}]+/m, "")
      .gsub(/(?:inline-size|block-size|width|height):\s*(?:min|max|clamp)\([^;}]+/m, "")
      .gsub(/grid-template-columns:[^;}]+/m, "")
  end
end
