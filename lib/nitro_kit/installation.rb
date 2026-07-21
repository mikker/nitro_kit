require "fileutils"
require "open3"
require "pathname"

module NitroKit
  class Installation
    ROOT = Pathname.new(File.expand_path("../..", __dir__))
    SKILLS = %w[nitro-kit-hotwire nitro-kit-rails nitro-kit-ui].freeze
    SKILL_ROOTS = [ ".agents/skills", ".claude/skills" ].freeze
    AGENTS_START = "<!-- nitro-kit:start -->"
    AGENTS_END = "<!-- nitro-kit:end -->"
    AGENTS_BLOCK = <<~MARKDOWN.freeze
      #{AGENTS_START}
      ## Nitro Kit 2

      This application uses Nitro Kit 2.x. Before changing Rails structure,
      Hotwire interactions, or UI, use the matching project-local Nitro Kit skill.
      Each skill resolves the installed gem with `bundle show nitro_kit` and reads
      its version-matched documentation.

      Do not use Nitro Kit 1.x APIs, `nk_*` helpers, copied Nitro components, or
      application-owned `controllers/nk`. Compose the installed Phlex Kit and keep
      routes, records, authorization, queries, DOM IDs, and server responses in the
      application.

      During migration, replace an existing form control only when Nitro Kit 2 has
      a genuine semantic and behavioral equivalent. Otherwise preserve the control
      as application-owned Rails and semantic HTML. Never downgrade specialized
      behavior or retain copied Nitro Kit 1.x source as the fallback.
      #{AGENTS_END}
    MARKDOWN

    Check = Struct.new(:status, :label, :detail, keyword_init: true)

    attr_reader :application_root

    def initialize(application_root)
      @application_root = Pathname.new(application_root)
    end

    def install
      { "AGENTS.md" => write_agents }.merge(write_skills)
    end

    def write_agents
      path = application_root.join("AGENTS.md")
      current = path.exist? ? path.read : ""
      updated = if current.include?(AGENTS_START)
        current.sub(/#{Regexp.escape(AGENTS_START)}.*?#{Regexp.escape(AGENTS_END)}/m, AGENTS_BLOCK.rstrip)
      else
        [ current.rstrip, AGENTS_BLOCK.rstrip ].reject(&:empty?).join("\n\n")
      end

      write(path, "#{updated.rstrip}\n")
    end

    def write_skills
      SKILL_ROOTS.product(SKILLS).to_h do |root, skill|
        destination = application_root.join(root, skill, "SKILL.md")
        source = skill_source(skill)
        [ destination.relative_path_from(application_root).to_s, write(destination, source.read) ]
      end
    end

    def prompt
      ROOT.join("docs/initialization_prompt.md").read
    end

    def copy_prompt
      command = clipboard_command
      raise "No supported clipboard command found" unless command

      IO.popen(command, "w") { _1.write(prompt) }
      raise "Clipboard command failed" unless $?.success?

      command.first
    end

    def checks
      [
        version_check,
        agents_check,
        skills_check,
        hotwire_check,
        stimulus_loader_check,
        stylesheet_check,
        phlex_kit_check,
        legacy_check
      ]
    end

    def healthy?
      checks.none? { _1.status == :fail }
    end

    private
      def write(path, contents)
        return :unchanged if path.exist? && path.read == contents

        FileUtils.mkdir_p(path.dirname)
        path.write(contents)
        :written
      end

      def skill_source(skill)
        ROOT.join("plugins/nitro-kit/skills", skill, "SKILL.md")
      end

      def version_check
        status = NitroKit::VERSION.start_with?("2.") ? :pass : :fail
        Check.new(status:, label: "Nitro Kit version", detail: NitroKit::VERSION)
      end

      def agents_check
        path = application_root.join("AGENTS.md")
        installed = path.exist? && path.read.include?(AGENTS_BLOCK.rstrip)
        Check.new(
          status: installed ? :pass : :fail,
          label: "AGENTS.md guidance",
          detail: installed ? "managed Nitro Kit 2 block is current" : "run the Nitro Kit install generator"
        )
      end

      def skills_check
        missing = SKILL_ROOTS.product(SKILLS).filter_map do |root, skill|
          path = application_root.join(root, skill, "SKILL.md")
          path.relative_path_from(application_root).to_s unless path.exist? && path.read == skill_source(skill).read
        end
        Check.new(
          status: missing.empty? ? :pass : :fail,
          label: "Project-local skills",
          detail: missing.empty? ? "Codex and Claude skill routers are current" : "missing or stale: #{missing.join(', ')}"
        )
      end

      def hotwire_check
        missing = %w[turbo-rails stimulus-rails].reject { Gem.loaded_specs.key?(_1) }
        Check.new(
          status: missing.empty? ? :pass : :fail,
          label: "Hotwire dependencies",
          detail: missing.empty? ? "Turbo and Stimulus are available" : "missing: #{missing.join(', ')}"
        )
      end

      def stimulus_loader_check
        path = application_root.join("app/javascript/controllers/index.js")
        ready = path.exist? && path.read.include?("eagerLoadControllersFrom")
        Check.new(
          status: ready ? :pass : :warn,
          label: "Stimulus loader",
          detail: ready ? "eager controller loading is configured" : "verify the application's controller registration"
        )
      end

      def stylesheet_check
        ready = application_files.any? do |path|
          path.read.include?("stylesheet_link_tag") && path.read.include?("nitro_kit")
        end
        Check.new(
          status: ready ? :pass : :warn,
          label: "Nitro Kit stylesheet",
          detail: ready ? "layout references the packaged stylesheet" : "add the packaged stylesheet to the application layout"
        )
      end

      def phlex_kit_check
        ready = application_root.glob("app/components/**/*.rb").any? { _1.read.match?(/include\s+(?:\(?\s*)?NitroKit\b/) }
        Check.new(
          status: ready ? :pass : :warn,
          label: "Phlex Kit base",
          detail: ready ? "an application component includes NitroKit" : "include NitroKit once in the application base component"
        )
      end

      def legacy_check
        legacy = [
          "app/components/nitro_kit",
          "app/helpers/nitro_kit",
          "app/javascript/controllers/nk"
        ].select { application_root.join(_1).exist? }
        Check.new(
          status: legacy.empty? ? :pass : :warn,
          label: "Nitro Kit 1.x shadows",
          detail: legacy.empty? ? "none found" : "review: #{legacy.join(', ')}"
        )
      end

      def application_files
        application_root.glob("app/{components,views}/**/*").select(&:file?)
      end

      def clipboard_command
        [ [ "pbcopy" ], [ "wl-copy" ], [ "xclip", "-selection", "clipboard" ], [ "clip" ] ].find do |command|
          executable?(command.first)
        end
      end

      def executable?(name)
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |directory|
          File.executable?(File.join(directory, name))
        end
      end
  end
end
