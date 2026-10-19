require "test_helper"
require "rails/generators/test_case"
require "generators/nitro_kit/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests NitroKit::InstallGenerator
  destination File.expand_path("../../tmp/install_generator", __dir__)
  setup { self.destination_root = File.join(self.class.destination_root, name) }
  setup :prepare_destination

  test "installs agent guidance, skills, and layout setup" do
    write_layout

    run_generator %w[--no-prompt]

    assert_file "AGENTS.md", /#{Regexp.escape(NitroKit::Installation::AGENTS_START)}/
    assert_file ".agents/skills/nitro-kit-ui/SKILL.md"
    assert_file ".claude/skills/nitro-kit-rails/SKILL.md"
    assert_file "app/components/ui/application_layout.rb", /NitroKit::AppearanceBootstrap/
  end

  test "pretend reports every change without writing anything" do
    write_layout
    File.write(File.join(destination_root, "AGENTS.md"), "# Existing guidance\n")
    before = snapshot

    output = run_generator %w[--no-prompt --pretend]

    assert_equal before, snapshot
    assert_match(/create\s+AGENTS\.md/, output)
    assert_match(%r{create\s+\.agents/skills/nitro-kit-ui/SKILL\.md}, output)
    assert_match(%r{create\s+app/components/ui/application_layout\.rb}, output)
    assert_match(/Nitro Kit version/, output)
  end

  test "reports unverified and optional outcomes for a configured manual integration" do
    File.write(File.join(destination_root, "Gemfile"), "")
    FileUtils.mkdir_p(File.join(destination_root, "config/nitro_kit"))
    File.write(File.join(destination_root, "config/nitro_kit/doctor.yml"), "theme_owner: application\nskill_roots: [.agents/skills]\n")
    path = File.join(destination_root, "app/views/layouts/application.html.erb")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, <<~ERB)
      <html>
        <head>
          <%= stylesheet_link_tag theme_stylesheet %>
        </head>
        <body><%= yield %></body>
      </html>
    ERB

    output = run_generator %w[--no-prompt]

    assert_no_file ".claude/skills/nitro-kit-ui/SKILL.md"
    assert_match(/UNVERIFIED\s+Stylesheet and appearance setup: .*check by hand/, output)
    assert_match(/OPTIONAL\s+Appearance bootstrap/, output)
    assert_match(/OPTIONAL\s+Project-local skills/, output)
    assert_match(/Doctor found no failures; 2 UNVERIFIED to check by hand; 2 OPTIONAL conventions not adopted/, output)
  end

  private
    def write_layout
      path = File.join(destination_root, "app/components/ui/application_layout.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, <<~RUBY)
        module UI
          class ApplicationLayout
            def view_template
              html do
                head do
                  stylesheet_link_tag("application", data: { turbo_track: "reload" })
                end
              end
            end
          end
        end
      RUBY
    end

    def snapshot
      Dir.glob("**/*", File::FNM_DOTMATCH, base: destination_root)
        .reject { File.directory?(File.join(destination_root, _1)) }
        .sort
        .to_h { [ _1, File.read(File.join(destination_root, _1)) ] }
    end
end
