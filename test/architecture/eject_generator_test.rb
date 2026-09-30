require "test_helper"
require "rails/generators/test_case"
require "generators/nitro_kit/eject_generator"
require "open3"

class EjectGeneratorTest < Rails::Generators::TestCase
  tests NitroKit::EjectGenerator
  destination File.expand_path("../../tmp/eject_generator", __dir__)
  setup { self.destination_root = File.join(self.class.destination_root, name) }
  setup :prepare_destination

  test "ejects Button with isolated CSS, icons, controller and provenance and renders in a fresh app" do
    run_generator [ "Button" ]
    assert_file "app/components/ui/ejected_button/button.rb", /module Ui::EjectedButton/
    assert_file "app/components/ui/ejected_button/icon.rb"
    assert_file "app/assets/stylesheets/ejected_button.css" do |css|
      assert_includes css, '[data-nk="ui-ejected-button-button"]'
      assert_includes css, "var(--nk-"
      assert_not_includes css, '[data-nk="button"]'
    end
    assert_file "app/javascript/controllers/ui/ejected_button/button_controller.js"
    assert_file "config/nitro_kit/ejected/button.json", /#{Regexp.escape(NitroKit::VERSION)}/
    html = render_snapshot('Ui::EjectedButton::Button.new("Save", icon: :check, type: :submit, submission_indicator: :spinner)')
    assert_includes html, 'data-nk="ui-ejected-button-button"'
    assert_includes html, 'data-slot="ui-ejected-button-button-label"'
    assert_includes html, 'data-nk="ui-ejected-button-icon"'
    assert_includes html, "ui--ejected-button--button"
  end

  test "ejects Avatar with controller targets and renders" do
    run_generator [ "Avatar" ]
    assert_file "app/javascript/controllers/ui/ejected_avatar/avatar_controller.js"
    html = render_snapshot('Ui::EjectedAvatar::Avatar.new(src: "/photo.png", alt: "Ada", fallback: "AL")')
    assert_includes html, 'data-controller="ui--ejected-avatar--avatar"'
    assert_includes html, 'data-ui--ejected-avatar--avatar-target="image"'
  end

  test "copies compound classes and transitive JavaScript imports" do
    run_generator [ "Dropzone" ]
    assert_file "app/javascript/controllers/ui/ejected_dropzone/dropzone/direct_upload.js"
    assert_file "app/javascript/controllers/ui/ejected_dropzone/dropzone_controller.js", /controllers\/ui\/ejected_dropzone\/dropzone\/direct_upload/
    html = render_snapshot('Ui::EjectedDropzone::Dropzone.new(id: "upload", name: "photo", label: "Upload", direct_upload: false)')
    assert_includes html, 'data-nk="ui-ejected-dropzone-dropzone"'
    run_generator [ "Toast" ]
    assert_file "app/components/ui/ejected_toast/toast.rb", /class Item < Component/
  end

  test "skips whole snapshot on conflict and supports explicit force" do
    run_generator [ "Button" ]
    path = File.join(destination_root, "app/components/ui/ejected_button/button.rb")
    File.write(path, "# My changes\n")
    run_generator [ "Button", "--skip" ]
    assert_equal "# My changes\n", File.read(path)
    run_generator [ "Button", "--force" ]
    assert_includes File.read(path), "class Button < Component"
  end

  test "unknown components fail before writing files" do
    error = assert_raises(ArgumentError) { NitroKit::Ejection.new("../Missing") }
    assert_includes error.message, "Unknown component"
    assert_includes error.message, "Button"
  end

  test "independent snapshots coexist with gem components" do
    run_generator [ "Button" ]
    run_generator [ "ButtonGroup" ]
    html = render_snapshot(<<~RUBY)
      Class.new(Phlex::HTML) do
        def view_template
          render NitroKit::Button.new("Gem")
          render Ui::EjectedButton::Button.new("Mine")
          render Ui::EjectedButtonGroup::ButtonGroup.new do |group|
            group.button("Group")
          end
        end
      end.new
    RUBY
    assert_includes html, 'data-nk="button"'
    assert_includes html, 'data-nk="ui-ejected-button-button"'
    assert_includes html, 'data-nk="ui-ejected-button-group-button"'
  end

  test "every supported snapshot eager loads with Zeitwerk in a clean process" do
    names = Dir["#{NitroKit::Ejection::ROOT}/app/components/nitro_kit/*.rb"].map { |path| File.basename(path, ".rb") }
    (names - NitroKit::Ejection::SUPPORT_FILES).each do |name|
      NitroKit::Ejection.new(name).files.each do |path, content|
        destination = File.join(destination_root, path)
        FileUtils.mkdir_p(File.dirname(destination))
        File.write(destination, content)
      end
    end
    html = render_snapshot('begin; loader.eager_load; Ui::EjectedCard::Card.new { |card| card.title("Title"); card.body { "Content" } }; end')
    assert_includes html, 'data-slot="ui-ejected-card-card-title"'
  end

  private
    def render_snapshot(expression)
      script = <<~RUBY
        require "bundler/setup"
        require "action_controller/railtie"
        require "nitro_kit"
        class SnapshotApp < Rails::Application
          config.root = #{destination_root.inspect}
          config.eager_load = false
          config.secret_key_base = "eject-test-secret"
          config.logger = Logger.new(File::NULL)
        end
        SnapshotApp.initialize!
        loader = Rails.autoloaders.main
        puts (#{expression}).call
      RUBY
      output, error, status = Open3.capture3("bundle", "exec", "ruby", "-e", script)
      assert status.success?, error
      output
    end
end
