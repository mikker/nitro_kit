require "test_helper"

load File.expand_path("../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class CssBundleTest < ActiveSupport::TestCase
  test "committed stylesheet matches its plain CSS sources" do
    assert NitroKit::CssBundle.current?, "Run `rake nitro_kit:css:build`"
  end

  test "foundation sources have deterministic order" do
    assert_equal %w[ layers.css tokens.css reset.css ],
      NitroKit::CssBundle.source_files.first(3).map { |path| path.basename.to_s }
  end

  test "stylesheet is independent from Tailwind processing" do
    css = NitroKit::CssBundle.compile

    refute_includes css, "@import \"tailwindcss\""
    refute_includes css, "@apply"
    assert_includes css, "nitro-kit.tokens"
    assert_includes css, "[data-theme=\"dark\"]"
    assert_includes css, ":where([data-nk], [data-nk] [data-slot])"
  end

  test "theme tokens follow the system only when no explicit theme is present" do
    source = NitroKit::CssBundle::ROOT.join("src/stylesheets/nitro_kit/tokens.css").read
    system_dark = theme_declarations(source, ":where(:root:not([data-theme]))")
    explicit_dark = theme_declarations(source, ':where([data-theme="dark"])')
    explicit_light = theme_declarations(source, ':where(:root, [data-theme="light"])')

    assert_includes source, "@media (prefers-color-scheme: dark)"
    assert_includes source, ':where(:root, [data-theme="light"])'
    assert_predicate system_dark, :any?
    assert_equal explicit_light.keys, explicit_dark.keys
    assert_equal explicit_dark, system_dark
  end

  test "component slot selectors are scoped through their owner" do
    unqualified_slot = /(?:\:where\(\s*|,\s*)\[data-slot=/m
    offenders = NitroKit::CssBundle.component_sources.select do |path|
      path.read.match?(unqualified_slot)
    end

    assert_empty offenders.map { |path| path.relative_path_from(NitroKit::CssBundle::ROOT).to_s }
  end

  test "form family is present as owner-scoped static CSS" do
    css = NitroKit::CssBundle.compile
    components = %w[
      label textarea select checkbox checkbox-group radio-button radio-button-group
      switch field field-group fieldset
    ]

    components.each { |component| assert_includes css, %([data-nk="#{component}"]) }
    assert_includes css, "[data-slot=\"switch-control\"]:checked"
    assert_includes css, "@media (prefers-reduced-motion: reduce)"
    refute_includes css, "transition: all"
  end

  test "gem package includes responsive layout sources and distribution assets" do
    specification = Gem::Specification.load(NitroKit::CssBundle::ROOT.join("nitro_kit.gemspec").to_s)

    assert_includes specification.files, "src/stylesheets/nitro_kit/tokens.css"
    assert_includes specification.files, "src/stylesheets/nitro_kit/components/layout.css"
    assert_includes specification.files, "src/stylesheets/nitro_kit/components/flex.css"
    assert_includes specification.files, "src/stylesheets/nitro_kit/components/grid.css"
    assert_includes specification.files, "app/assets/stylesheets/nitro_kit.css"
    assert_includes specification.files, "app/assets/stylesheets/nitro_kit-tailwind-v4.css"
    assert_includes specification.files, "app/components/nitro_kit/responsive_value.rb"
    assert_includes specification.files, "app/components/nitro_kit/flex.rb"
    assert_includes specification.files, "app/components/nitro_kit/grid.rb"
    assert_includes specification.files, "app/components/nitro_kit/confirm_dialog.rb"
    assert_includes specification.files, "app/javascript/nitro_kit.js"
    assert_includes specification.files, "app/javascript/controllers/nk/confirm_dialog_controller.js"
    assert_includes specification.files, "src/stylesheets/nitro_kit/components/confirm_dialog.css"

    %w[h_stack.rb v_stack.rb].each do |name|
      refute_includes specification.files, "app/components/nitro_kit/#{name}"
    end

    %w[h_stack.css v_stack.css stack.css].each do |name|
      refute_includes specification.files, "src/stylesheets/nitro_kit/components/#{name}"
    end
  end

  private

  def theme_declarations(source, selector)
    body = source.match(/#{Regexp.escape(selector)}\s*\{(?<body>[^}]*)\}/m)&.[](:body)
    return {} unless body

    body.scan(/(?<name>color-scheme|--nk-color-[a-z-]+):\s*(?<value>[^;]+);/)
      .to_h
      .transform_values(&:strip)
  end
end
