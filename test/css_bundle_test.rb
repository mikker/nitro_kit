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

  test "gem package includes CSS sources and distribution assets" do
    specification = Gem::Specification.load(NitroKit::CssBundle::ROOT.join("nitro_kit.gemspec").to_s)

    assert_includes specification.files, "src/stylesheets/nitro_kit/tokens.css"
    assert_includes specification.files, "app/assets/stylesheets/nitro_kit.css"
    assert_includes specification.files, "app/assets/stylesheets/nitro_kit-tailwind-v4.css"
  end
end
