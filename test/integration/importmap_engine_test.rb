require "test_helper"
require "json"
require "open3"
require "rbconfig"

class ImportmapEngineTest < ActionDispatch::IntegrationTest
  test "registers the engine import map and JavaScript cache sweepers" do
    assert_includes Rails.application.config.importmap.paths, NitroKit::Engine::IMPORTMAP_PATH

    NitroKit::Engine::JAVASCRIPT_PATHS.each do |path|
      assert_includes Rails.application.config.importmap.cache_sweepers, path
      assert_includes Rails.application.config.assets.paths, path
    end
  end

  test "pins every Nitro controller from gem-owned assets" do
    controller_root = NitroKit::Engine.root.join("app/javascript/controllers")

    controller_root.glob("nk/*_controller.js").each do |path|
      name = "controllers/#{path.relative_path_from(controller_root).sub_ext("")}"
      asset = imports.fetch(name)

      get asset
      assert_response :success, name
      assert_includes response.body, "@hotwired/stimulus"
    end
  end

  test "pins the Nitro Kit bootstrap" do
    asset = imports.fetch("nitro_kit")

    get asset
    assert_response :success
    assert_includes response.body, "Turbo.config.forms.confirm"
  end

  test "does not pin removed third-party controller runtimes" do
    stale_pins = [ "@github/combobox-nav", "@floating-ui/core", "@floating-ui/dom" ]

    stale_pins.each do |name|
      refute Rails.application.importmap.packages.key?(name)
      refute imports.key?(name)
    end
  end

  test "packages the import map and controllers without vendored runtimes" do
    specification = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s)

    assert_includes specification.files, "config/importmap.rb"
    assert_includes specification.files, "app/javascript/nitro_kit.js"
    assert_includes specification.files, "app/javascript/controllers/nk/dropdown_controller.js"
    assert_includes specification.files, "app/javascript/controllers/nk/tooltip_controller.js"
    refute_includes specification.files, "app/javascript/controllers/nk/accordion_controller.js"
    assert_includes specification.files, "app/javascript/controllers/nk/dialog_controller.js"
    assert_includes specification.files, "app/javascript/controllers/nk/overlay_position.js"
    refute specification.files.any? { |path| path.start_with?("vendor/javascript/") }
  end

  test "initializes without importmap-rails" do
    script = <<~RUBY
      require "rails"
      require "nitro_kit/engine"

      abort "Importmap loaded unexpectedly" if defined?(Importmap)

      class ImportmaplessApplication < Rails::Application
        config.eager_load = false
        config.secret_key_base = "test"
      end

      ImportmaplessApplication.initialize!
    RUBY

    _output, error, status = Open3.capture3(
      RbConfig.ruby,
      "-I#{NitroKit::Engine.root.join("lib")}",
      "-e",
      script,
      chdir: NitroKit::Engine.root.to_s
    )

    assert status.success?, error
  end

  private
    def imports
      @imports ||= JSON.parse(
        Rails.application.importmap.to_json(resolver: ActionController::Base.helpers)
      ).fetch("imports")
    end
end
