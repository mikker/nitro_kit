require "test_helper"
require "tmpdir"
require "nitro_kit/installation"

class InstallationTest < ActiveSupport::TestCase
  test "installs version-routed skills and preserves existing agent guidance" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("AGENTS.md").write("# Existing application guidance\n")
      installation = NitroKit::Installation.new(root)

      first = installation.install
      second = installation.install

      assert_equal :written, first.fetch("AGENTS.md")
      assert second.values.all? { _1 == :unchanged }
      assert_includes root.join("AGENTS.md").read, "# Existing application guidance"
      assert_equal 1, root.join("AGENTS.md").read.scan(NitroKit::Installation::AGENTS_START).size

      NitroKit::Installation::SKILL_ROOTS.product(NitroKit::Installation::SKILLS).each do |skill_root, skill|
        installed = root.join(skill_root, skill, "SKILL.md")
        source = NitroKit::Installation::ROOT.join("plugins/nitro-kit/skills", skill, "SKILL.md")

        assert_equal source.read, installed.read
      end
    end
  end

  test "refreshes only the managed agents block" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("AGENTS.md").write(<<~MARKDOWN)
        Before

        #{NitroKit::Installation::AGENTS_START}
        stale
        #{NitroKit::Installation::AGENTS_END}

        After
      MARKDOWN

      NitroKit::Installation.new(root).install
      contents = root.join("AGENTS.md").read

      assert_includes contents, "Before"
      assert_includes contents, "After"
      assert_includes contents, "This application uses Nitro Kit 2.x"
      refute_includes contents, "stale"
      assert_equal 1, contents.scan(NitroKit::Installation::AGENTS_START).size
    end
  end

  test "doctor separates required integration from application next steps" do
    Dir.mktmpdir do |directory|
      installation = NitroKit::Installation.new(directory)
      installation.install
      checks = installation.checks.index_by(&:label)

      assert_equal :pass, checks.fetch("Nitro Kit version").status
      assert_equal :pass, checks.fetch("AGENTS.md guidance").status
      assert_equal :pass, checks.fetch("Project-local skills").status
      assert_equal :pass, checks.fetch("Hotwire dependencies").status
      assert_equal :fail, checks.fetch("Stylesheet and appearance setup").status
      assert_equal :warn, checks.fetch("Phlex Kit base").status
      refute installation.healthy?
    end
  end

  test "installer additively completes a standard Phlex layout and preserves call options" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("Gemfile").write("gem \"lexxy\"\n")
      write_phlex_layout(root, <<~RUBY)
        render NitroKit::AppearanceBootstrap.new(default: :dark, nonce: layout_nonce)
        stylesheet_link_tag("lexxy", media: "all", nonce: layout_nonce)
        stylesheet_link_tag("application", data: { turbo_track: "reload" }, media: "screen")
      RUBY
      installation = NitroKit::Installation.new(root)

      first = installation.install
      installed = root.join("app/components/ui/application_layout.rb").read
      second = installation.install

      assert_equal :written, first.fetch("app/components/ui/application_layout.rb")
      assert_equal :unchanged, second.fetch("app/components/ui/application_layout.rb")
      assert_equal 1, installed.scan("NitroKit::AppearanceBootstrap").size
      assert_equal 3, installed.scan("stylesheet_link_tag").size
      assert_includes installed, "render NitroKit::AppearanceBootstrap.new(default: :dark, nonce: layout_nonce)"
      assert_includes installed, 'stylesheet_link_tag("lexxy", media: "all", nonce: layout_nonce)'
      assert_includes installed, 'stylesheet_link_tag("application", data: { turbo_track: "reload" }, media: "screen")'
      assert_operator installed.index('"lexxy"'), :<, installed.index('"nitro_kit"')
      assert_operator installed.index('"nitro_kit"'), :<, installed.index('"application"')
      assert_equal :pass, installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup").status
    end
  end

  test "installer adds a safe bootstrap and Tailwind entries without requiring a nonce helper" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("Gemfile").write("gem \"tailwindcss-rails\"\n")
      write_erb_layout(root, '<%= stylesheet_link_tag "tailwind", "application", "data-turbo-track": "reload", media: "all" %>')

      installation = NitroKit::Installation.new(root)
      installation.install
      installed = root.join("app/views/layouts/application.html.erb").read

      assert_includes installed, "<%= render NitroKit::AppearanceBootstrap.new %>"
      refute_includes installed, "content_security_policy_nonce"
      assert_includes installed, '<%= stylesheet_link_tag "nitro_kit-tailwind-v4", "data-turbo-track": "reload" %>'
      assert_includes installed, '<%= stylesheet_link_tag "nitro_kit", "data-turbo-track": "reload" %>'
      assert_includes installed, '<%= stylesheet_link_tag "tailwind", "application", "data-turbo-track": "reload", media: "all" %>'
      assert_operator installed.index("NitroKit::AppearanceBootstrap"), :<, installed.index('"nitro_kit-tailwind-v4"')
      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
    end
  end

  test "installer detects parenthesized and unparenthesized optional Gemfile dependencies" do
    {
      'gem "lexxy"' => "lexxy",
      'gem("lexxy")' => "lexxy",
      'gem "tailwindcss-rails"' => "tailwind",
      'gem("tailwindcss-rails")' => "tailwind"
    }.each do |declaration, expected_asset|
      Dir.mktmpdir do |directory|
        root = Pathname.new(directory)
        root.join("Gemfile").write("#{declaration}\n")
        write_erb_layout(root, "")

        NitroKit::Installation.new(root).install
        installed = root.join("app/views/layouts/application.html.erb").read

        assert_includes installed, %(stylesheet_link_tag "#{expected_asset}"), declaration
      end
    end
  end

  test "installer adds application only when its asset exists or the layout already names it" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_phlex_layout(root, "")

      NitroKit::Installation.new(root).install
      without_asset = root.join("app/components/ui/application_layout.rb").read

      assert_includes without_asset, 'stylesheet_link_tag("nitro_kit"'
      refute_includes without_asset, 'stylesheet_link_tag("application"'

      write_phlex_layout(root, "")
      write_file(root, "app/assets/stylesheets/application.css", "body {}\n")
      NitroKit::Installation.new(root).install
      with_asset = root.join("app/components/ui/application_layout.rb").read

      assert_operator with_asset.index('"nitro_kit"'), :<, with_asset.index('"application"')
    end
  end

  test "installer leaves dynamic and anchor-ambiguous layouts unchanged with actionable diagnostics" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      dynamic = write_erb_layout(root, '<%= stylesheet_link_tag stylesheet_bundle, media: "screen" %>')
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal dynamic, root.join("app/views/layouts/application.html.erb").read
      diagnostic = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, diagnostic.status
      assert_includes diagnostic.detail, "left the layout unchanged"
      assert_includes diagnostic.detail, "dynamic assets"

      grouped = write_erb_layout(root, <<~ERB.strip)
        <%= render NitroKit::AppearanceBootstrap.new(default: :dark) %>
        <%= stylesheet_link_tag "lexxy", "application", media: "screen" %>
      ERB
      root.join("Gemfile").write("gem \"lexxy\"\n")
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal grouped, root.join("app/views/layouts/application.html.erb").read
      assert_includes installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup").detail,
        "combined stylesheet call spans a required insertion point"

      custom = write_erb_layout(root, '<%= stylesheet_link_tag "editor", "application", media: "screen" %>')
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal custom, root.join("app/views/layouts/application.html.erb").read
      assert_includes installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup").detail,
        "combines custom and canonical assets"
    end
  end

  test "installer and doctor reject body-only and mixed ERB layout expressions" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      body_setup = <<~ERB.strip
        <%= render NitroKit::AppearanceBootstrap.new %>
        <%= stylesheet_link_tag "nitro_kit", "data-turbo-track": "reload" %>
      ERB
      body_only = write_erb_layout(root, "", body_setup:)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal body_only, root.join("app/views/layouts/application.html.erb").read
      body_only_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, body_only_check.status
      assert_includes body_only_check.detail, "outside the document head"

      mixed = write_erb_layout(root, body_setup, body_setup:)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal mixed, root.join("app/views/layouts/application.html.erb").read
      mixed_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, mixed_check.status
      assert_includes mixed_check.detail, "outside the document head"
    end
  end

  test "installer and doctor reject body-only and mixed Phlex layout expressions" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      body_setup = <<~RUBY
        render NitroKit::AppearanceBootstrap.new
        stylesheet_link_tag("nitro_kit", data: { turbo_track: "reload" })
      RUBY
      body_only = write_phlex_layout(root, "", body_setup:)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/components/ui/application_layout.rb")
      assert_equal body_only, root.join("app/components/ui/application_layout.rb").read
      body_only_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, body_only_check.status
      assert_includes body_only_check.detail, "outside the document head"

      mixed = write_phlex_layout(root, body_setup, body_setup:)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/components/ui/application_layout.rb")
      assert_equal mixed, root.join("app/components/ui/application_layout.rb").read
      mixed_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, mixed_check.status
      assert_includes mixed_check.detail, "outside the document head"
    end
  end

  test "installer leaves layouts with ambiguous head boundaries or ownership unchanged" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      erb = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_link_tag "application" %>
          <body><%= yield %></body>
        </html>
      ERB
      write_file(root, "app/views/layouts/application.html.erb", erb)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/views/layouts/application.html.erb")
      assert_equal erb, root.join("app/views/layouts/application.html.erb").read
      erb_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, erb_check.status
      assert_includes erb_check.detail, "expected one conventional </head> closing tag"
    end

    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      phlex = <<~RUBY
        class ApplicationLayout
          def view_template
            html do
              wrapper do
                head do
                  stylesheet_link_tag("application")
                end
              end
            end
          end
        end
      RUBY
      write_file(root, "app/components/application_layout.rb", phlex)
      installation = NitroKit::Installation.new(root)

      assert_equal :unchanged, installation.install.fetch("app/components/application_layout.rb")
      assert_equal phlex, root.join("app/components/application_layout.rb").read
      phlex_check = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, phlex_check.status
      assert_includes phlex_check.detail, "head block must be owned directly"
    end
  end

  test "doctor reports missing duplicate and misordered stylesheet setup" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_phlex_layout(root, 'stylesheet_link_tag("nitro_kit", "application", data: { turbo_track: "reload" })')
      installation = NitroKit::Installation.new(root)

      missing = installation.checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, missing.status
      assert_includes missing.detail, "add one NitroKit::AppearanceBootstrap"

      write_phlex_layout(root, <<~RUBY)
        stylesheet_link_tag("application", "nitro_kit", "nitro_kit", data: { turbo_track: "reload" })
        render NitroKit::AppearanceBootstrap.new
        render NitroKit::AppearanceBootstrap.new
      RUBY
      duplicate = NitroKit::Installation.new(root).checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, duplicate.status
      assert_includes duplicate.detail, 'remove duplicate stylesheet "nitro_kit"'
      assert_includes duplicate.detail, "remove duplicate NitroKit::AppearanceBootstrap"

      write_phlex_layout(root, <<~RUBY)
        stylesheet_link_tag("application", "nitro_kit", data: { turbo_track: "reload" })
        render NitroKit::AppearanceBootstrap.new
      RUBY
      misordered = NitroKit::Installation.new(root).checks.index_by(&:label).fetch("Stylesheet and appearance setup")
      assert_equal :fail, misordered.status
      assert_includes misordered.detail, "move the existing call without changing its options"
    end
  end

  test "doctor inventories concrete Nitro Kit 1 conventions and migration dispositions" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      write_file(root, "app/views/accounts/show.html.erb", <<~ERB)
        <%= nk_button_link_to "Edit", edit_account_path %>
        <%= nk_datepicker name: "account[start_on]" %>
        <%= nk_email_field_tag "account[email]" %>
        <%= nk_primary_button_link_to "Save", account_path %>
        <%# nk_button_to "Comment only", account_path %>
        <%= "nk_form_with in a string" %>
        <%= :nk_button_to %>
      ERB
      write_file(root, "app/models/account.rb", <<~RUBY)
        # nk_button_to "Comment only"
        EXAMPLE = "nk_form_with in a string"
        HELPER_NAME = :nk_button_to
      RUBY
      write_file(root, "app/components/nitro_kit/button.rb", "module NitroKit; class Button; end; end\n")
      write_file(root, "app/components/nitro_kit/alert.rb", "module NitroKit; class CustomAlert; end; end\n")
      write_file(root, "app/components/nitro_kit/admin/button.rb", "module NitroKit; module Admin; class Button; end; end; end\n")
      write_file(root, "app/components/nitro_kit/transcript_toolbar.rb", "module NitroKit; class TranscriptToolbar; end; end\n")
      write_file(root, "app/javascript/controllers/nk/dropdown_controller.js", "export default class {}\n")
      write_file(root, "app/javascript/controllers/nk/transcript_controller.js", "export default class {}\n")
      write_file(root, "vendor/javascript/@floating-ui--dom.js", "export {}\n")
      write_file(root, "config/importmap.rb", 'pin "@github/combobox-nav"\n')
      root.join("Gemfile").write("gem \"tailwind_merge\"\n")

      checks = NitroKit::Installation.new(root).checks.index_by(&:label)

      helpers = checks.fetch("Migration: Legacy helpers")
      assert_equal :warn, helpers.status
      assert_includes helpers.detail, "app/views/accounts/show.html.erb:1"
      assert_includes helpers.detail, "replace with Button(..., href:)"
      assert_includes helpers.detail, "Input(type: :email)"
      assert_includes helpers.detail, "pass the old variant explicitly"

      components = checks.fetch("Migration: Copied or shadow components")
      assert_includes components.detail, "unresolved: app/components/nitro_kit/button.rb"
      assert_includes components.detail, "application-owned: app/components/nitro_kit/alert.rb"
      assert_includes components.detail, "application-owned: app/components/nitro_kit/admin/button.rb"
      assert_includes components.detail, "application-owned: app/components/nitro_kit/transcript_toolbar.rb"

      controllers = checks.fetch("Migration: Custom or legacy controllers")
      assert_includes controllers.detail, "unresolved: app/javascript/controllers/nk/dropdown_controller.js"
      assert_includes controllers.detail, "application-owned: app/javascript/controllers/nk/transcript_controller.js"

      dependencies = checks.fetch("Migration: Vendored dependencies")
      assert_includes dependencies.detail, "vendor/javascript/@floating-ui--dom.js"
      assert_includes dependencies.detail, "config/importmap.rb:1"
      assert_includes dependencies.detail, "Gemfile:1"

      replacements = checks.fetch("Migration: Known replacements")
      assert_includes replacements.detail, "NitroKit::Button"
      assert_includes replacements.detail, "gem-owned Nitro behavior"
      refute_includes replacements.detail, "app/views/accounts/show.html.erb"

      dispositions = checks.fetch("Migration: Unresolved or application-owned items")
      assert_includes dispositions.detail, "unresolved:"
      assert_includes dispositions.detail, "application-owned:"
      assert_includes dispositions.detail, "per-file replacement"
      refute_includes helpers.detail, "Comment only"
      assert_equal 4, helpers.detail.lines.size
    end
  end

  test "doctor marks empty migration categories as migrated" do
    Dir.mktmpdir do |directory|
      migration_checks = NitroKit::Installation.new(directory).checks.select { _1.label.start_with?("Migration:") }

      assert migration_checks.all? { _1.status == :pass }
      assert migration_checks.all? { _1.detail == "migrated: none found" }
    end
  end

  test "ships a version-specific initialization prompt" do
    prompt = NitroKit::Installation.new(Dir.pwd).prompt

    assert_includes prompt, "Nitro Kit 2"
    assert_includes prompt, "bundle show nitro_kit"
    assert_includes prompt, "nitro_kit:doctor"
    refute_includes prompt, "launch"
  end

  test "copies the initialization prompt through an available clipboard command" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      clipboard = root.join("clipboard")
      command = root.join("pbcopy")
      command.write("#!/bin/sh\ncat > #{clipboard}\n")
      command.chmod(0o755)

      previous_path = ENV["PATH"]
      ENV["PATH"] = [ directory, previous_path ].compact.join(File::PATH_SEPARATOR)
      used = NitroKit::Installation.new(root).copy_prompt

      assert_equal "pbcopy", used
      assert_equal NitroKit::Installation.new(root).prompt, clipboard.read
    ensure
      ENV["PATH"] = previous_path
    end
  end

  private
    def write_phlex_layout(root, setup, body_setup: nil)
      body = if body_setup
        <<~RUBY
                body do
        #{body_setup.lines.map { "          #{_1}" }.join.rstrip}
                end
        RUBY
      end
      contents = <<~RUBY
        module UI
          class ApplicationLayout
            def view_template
              html do
                head do
        #{setup.lines.map { "          #{_1}" }.join.rstrip}
                end
        #{body.to_s.rstrip}
              end
            end
          end
        end
      RUBY
      write_file(root, "app/components/ui/application_layout.rb", contents)
      contents
    end

    def write_erb_layout(root, setup, body_setup: nil)
      body = body_setup ? "\n#{body_setup.lines.map { "    #{_1}" }.join.rstrip}\n  " : "<%= yield %>"
      contents = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
        #{setup.lines.map { "    #{_1}" }.join.rstrip}
          </head>
          <body>#{body}</body>
        </html>
      ERB
      write_file(root, "app/views/layouts/application.html.erb", contents)
      contents
    end

    def write_file(root, name, contents)
      path = root.join(name)
      FileUtils.mkdir_p(path.dirname)
      path.write(contents)
    end
end
