require "test_helper"

class GalleryThemePresetTest < ActiveSupport::TestCase
  test "locks the versioned choices and defaults" do
    assert_equal 1, Gallery::ThemePreset::VERSION
    assert_equal %i[v accent neutral radius density font shell], Gallery::ThemePreset::PARAMETER_ORDER
    assert_equal %i[blue indigo violet rose amber emerald neutral], Gallery::ThemePreset::CHOICES.fetch(:accent)
    assert_equal %i[slate gray zinc neutral stone], Gallery::ThemePreset::CHOICES.fetch(:neutral)
    assert_equal %i[none sm md lg], Gallery::ThemePreset::CHOICES.fetch(:radius)
    assert_equal %i[compact comfortable], Gallery::ThemePreset::CHOICES.fetch(:density)
    assert_equal %i[system humanist serif mono], Gallery::ThemePreset::CHOICES.fetch(:font)
    assert_equal %i[sidebar topbar hybrid], Gallery::ThemePreset::CHOICES.fetch(:shell)

    assert_equal(
      Gallery::ThemePreset.new,
      Gallery::ThemePreset.new(
        accent: :blue,
        neutral: :zinc,
        radius: :md,
        density: :comfortable,
        font: :system,
        shell: :sidebar
      )
    )
  end

  test "is immutable and rejects vocabulary outside the closed choices" do
    preset = Gallery::ThemePreset.new

    assert_predicate preset, :frozen?
    assert_raises(NoMethodError) { preset.accent = :rose }
    error = assert_raises(ArgumentError) { Gallery::ThemePreset.new(radius: :pill) }
    assert_equal "Unsupported radius: :pill", error.message
    assert_raises(ArgumentError) { Gallery::ThemePreset.new(accent: "blue") }
  end

  test "parses valid readable parameters and round trips them in stable order" do
    result = Gallery::ThemePreset.parse(
      "v" => "1",
      "accent" => "rose",
      "neutral" => "stone",
      "radius" => "lg",
      "density" => "compact",
      "font" => "serif",
      "shell" => "hybrid"
    )

    assert_empty result.errors
    assert_equal :rose, result.preset.accent
    assert_equal :stone, result.preset.neutral
    assert_equal :lg, result.preset.radius
    assert_equal :compact, result.preset.density
    assert_equal :serif, result.preset.font
    assert_equal :hybrid, result.preset.shell
    assert_equal(
      "v=1&accent=rose&neutral=stone&radius=lg&density=compact&font=serif&shell=hybrid",
      result.preset.query_string
    )
    assert_equal result.preset, Gallery::ThemePreset.parse(result.preset.query_parameters).preset
  end

  test "falls back safely for unsupported versions and choices without reflecting input" do
    unsupported_version = Gallery::ThemePreset.parse(
      "v" => "99",
      "accent" => "rose",
      "shell" => "hybrid"
    )

    assert_equal Gallery::ThemePreset.new, unsupported_version.preset
    assert_equal 1, unsupported_version.errors.length
    assert_includes unsupported_version.errors.first, "Version 1 defaults"

    unsupported_choice = Gallery::ThemePreset.parse(
      "accent" => '<script>alert("no")</script>',
      "neutral" => [ "stone" ],
      "radius" => "lg"
    )

    assert_equal :blue, unsupported_choice.preset.accent
    assert_equal :zinc, unsupported_choice.preset.neutral
    assert_equal :lg, unsupported_choice.preset.radius
    assert_equal 2, unsupported_choice.errors.length
    refute_includes unsupported_choice.errors.join, "script"
    assert_predicate unsupported_choice.errors, :frozen?
  end

  test "exports deterministic public token CSS with stable selector and declaration order" do
    preset = Gallery::ThemePreset.new(
      accent: :violet,
      neutral: :stone,
      radius: :lg,
      density: :compact,
      font: :mono,
      shell: :topbar
    )

    css = preset.css

    assert_equal css, preset.css
    assert_operator css.index(':root, [data-theme="light"]'), :<, css.index('[data-theme="dark"]')
    assert_includes css, "@media (prefers-color-scheme: dark)"
    assert_includes css, ":root:not([data-theme])"
    assert_includes css, "--nk-color-primary: oklch(0.541 0.281 293.009);"
    assert_includes css, "--nk-color-primary: oklch(0.702 0.183 293.541);"
    assert_includes css, "--nk-font-sans: var(--nk-font-mono);"
    assert_includes css, "--nk-radius-xl: 1rem;"
    assert_includes css, "--nk-space: 0.2rem;"
    refute_includes css, "--_nk-"

    css.scan(/(?<!_)--nk-[\w-]+/).each do |token|
      assert token.start_with?("--nk-")
    end

    blocks = css.scan(/(?:^|\n)(?:[^@\n][^{]+|\s+:root:not\(\[data-theme\]\)) \{\n(?<declarations>(?:\s+--nk-[^\n]+\n)+)/)
    assert blocks.any?
    blocks.flatten.each do |declarations|
      names = declarations.scan(/^\s+(--nk-[\w-]+):/).flatten
      assert_equal names.sort, names
    end
  end

  test "omits values unchanged from Nitro defaults" do
    css = Gallery::ThemePreset.new.css

    refute_includes css, "--nk-font-sans:"
    refute_includes css, "--nk-radius-md:"
    refute_includes css, "--nk-space:"
    refute_includes css, "--nk-color-focus: oklch(0.546 0.245 262.881);"
    refute_includes css, "--nk-color-canvas:"
    assert_includes css, "--nk-color-primary: oklch(0.546 0.245 262.881);"
  end

  test "dark export resets a light override even when the dark value matches Nitro defaults" do
    css = Gallery::ThemePreset.new(accent: :neutral).css
    dark_block = css[/\[data-theme="dark"\] \{(?<body>.*?)\n\}/m, :body]
    system_block = css[/@media \(prefers-color-scheme: dark\) \{.*?:root:not\(\[data-theme\]\) \{(?<body>.*?)\n  \}/m, :body]

    assert_includes css, "--nk-color-primary: oklch(0.269 0 0);"
    assert_includes dark_block, "--nk-color-primary: oklch(0.985 0 0);"
    assert_includes system_block, "--nk-color-primary: oklch(0.985 0 0);"
  end

  test "emits only composition Ruby for the selected shell" do
    ruby = Gallery::ThemePreset.new(shell: :hybrid).app_shell_ruby

    assert_includes ruby, 'NitroKit::AppShell.new(id: "workspace", layout: :hybrid)'
    assert_includes ruby, "NitroKit::AppNavigation.new"
    assert_includes ruby, "NitroKit::Button.new"
    refute_includes ruby, "class AppShell"
    refute_includes ruby, "desperately_need_a_class"
    refute_includes ruby, "--nk-"
  end

  test "shares one public token schema with the browser" do
    schema = Gallery::ThemePreset.schema

    assert_predicate schema, :frozen?
    assert_predicate schema.fetch(:tokenMaps), :frozen?
    assert_predicate schema.fetch(:shellExamples), :frozen?
    assert_equal 1, schema.fetch(:version)
    assert_equal %w[v accent neutral radius density font shell], schema.fetch(:parameterOrder)
    assert_equal "blue", schema.dig(:defaults, :accent)
    assert_equal %w[sidebar topbar hybrid], schema.dig(:choices, :shell)
    assert_includes schema.dig(:shellExamples, "topbar"), "layout: :topbar"

    schema.fetch(:tokenMaps).each_value do |choices|
      choices.each_value do |scopes|
        scopes.each_value do |tokens|
          tokens.each_key do |token|
            assert token.start_with?("--nk-"), "expected a public Nitro token, got #{token.inspect}"
            refute token.start_with?("--_nk-")
          end
        end
      end
    end
  end

  test "keeps copied baselines aligned with the canonical token source" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/tokens.css").read
    selectors = {
      shared: ":where(:root)",
      light: ':where(:root, [data-theme="light"])',
      dark: ':where([data-theme="dark"])'
    }

    selectors.each do |scope, selector|
      actual = tokens_from_block(source, selector)
      expected = Gallery::ThemePreset::BASELINES.fetch(scope)

      assert_equal expected, actual.slice(*expected.keys), "#{scope} baseline drifted from #{selector}"
    end
  end

  private

  def tokens_from_block(source, selector)
    match = source.match(/#{Regexp.escape(selector)}\s*\{(?<body>.*?)^\s*\}/m)
    assert match, "missing canonical token scope #{selector}"

    match[:body].scan(/(?<name>--nk-[\w-]+):\s*(?<value>.*?);/m).to_h do |name, value|
      [ name, value.gsub(/\s+/, " ").strip ]
    end
  end
end
