require "test_helper"
require "json"
require "open3"
require "rbconfig"

class LegacySurfaceTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root

  test "ships only the direct Phlex component surface" do
    assert_empty ROOT.glob("app/helpers/nitro_kit/**/*")
    assert_equal [ ROOT.join("lib/generators/nitro_kit/install_generator.rb") ],
      ROOT.glob("lib/generators/nitro_kit/**/*").select(&:file?)
    refute ROOT.join("lib/nitro_kit/schema_builder.rb").exist?
    refute ROOT.join("lib/nitro_kit/variants.rb").exist?
    refute NitroKit::Component.respond_to?(:from_template)
    refute_includes NitroKit::Component.instance_methods(false), :builder
    refute_includes NitroKit::Component.private_instance_methods(false), :mattr
    refute_includes NitroKit::Component.private_instance_methods(false), :merge_class
  end

  test "package excludes helper generator Tailwind runtime and vendored JavaScript paths" do
    specification = Gem::Specification.load(ROOT.join("nitro_kit.gemspec").to_s)

    refute_includes specification.dependencies.map(&:name), "tailwind_merge"
    refute specification.files.any? { |path| path.start_with?("app/helpers/") }
    assert_equal [ "lib/generators/nitro_kit/install_generator.rb" ],
      specification.files.grep(%r{\Alib/generators/})
    refute specification.files.any? { |path| path.start_with?("vendor/javascript/") }
    refute_includes specification.files, "Rakefile"
    refute ROOT.join("Gemfile").read.include?("tailwindcss-rails")
    refute JSON.parse(ROOT.join("package.json").read).fetch("devDependencies").key?("prettier-plugin-tailwindcss")
  end

  test "tooling keeps lint at the Ruby boundary" do
    tooling = JSON.parse(ROOT.join("package.json").read)
    dependencies = tooling.fetch("devDependencies")

    assert_empty dependencies.keys.grep(/\A@herb-tools\//)
    refute tooling.fetch("scripts", {}).keys.any? { |name| name.include?("lint") }
    refute ROOT.join(".herb.yml").exist?
    assert ROOT.join("bin/rubocop").exist?
  end

  test "dummy app uses the gallery root without the legacy template catalog" do
    assert Rails.application.routes.url_helpers.respond_to?(:root_path)
    refute Rails.application.routes.url_helpers.respond_to?(:tests_path)
    assert_empty ROOT.glob("test/dummy/app/views/tests/**/*").select(&:file?)
    refute ROOT.join("test/dummy/app/controllers/tests_controller.rb").exist?
    refute_includes ROOT.join("test/dummy/config/puma.rb").read, "tailwindcss"

    route = Rails.application.routes.recognize_path("/")
    assert_equal "gallery/home", route.fetch(:controller)
    assert_equal "show", route.fetch(:action)
  end

  test "development environment boots without a Tailwind runtime" do
    script = <<~RUBY
      ENV["RAILS_ENV"] = "development"
      require File.expand_path("test/dummy/config/environment", Dir.pwd)
      abort "wrong root" unless Rails.application.routes.recognize_path("/")[:controller] == "gallery/home"
      abort "tailwind runtime loaded" if Gem.loaded_specs.key?("tailwindcss-rails")
    RUBY

    _output, error, status = Open3.capture3(
      { "RAILS_ENV" => "development" },
      RbConfig.ruby,
      "-e",
      script,
      chdir: ROOT.to_s
    )

    assert status.success?, error
  end

  test "public entrypoint loads before a Rails application boots" do
    script = <<~RUBY
      require "nitro_kit"
      abort "wrong version" unless NitroKit::VERSION == "#{NitroKit::VERSION}"
      abort "missing engine" unless defined?(NitroKit::Engine)
    RUBY

    _output, error, status = Open3.capture3(
      RbConfig.ruby,
      "-I",
      ROOT.join("lib").to_s,
      "-e",
      script,
      chdir: ROOT.to_s
    )

    assert status.success?, error
  end

  test "engine repository exposes documented top-level CSS tasks" do
    output, error, status = Open3.capture3(
      RbConfig.ruby,
      Gem.bin_path("rake", "rake"),
      "-T",
      "nitro_kit",
      chdir: ROOT.to_s
    )

    assert status.success?, error
    assert_includes output, "rake nitro_kit:css:build"
    assert_includes output, "rake nitro_kit:css:check"
  end
end
