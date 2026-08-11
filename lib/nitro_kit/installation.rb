require "fileutils"
require "open3"
require "pathname"
require "ripper"
require "nitro_kit/migration_inventory"

module NitroKit
  class Installation
    ROOT = Pathname.new(File.expand_path("../..", __dir__))
    SKILLS = %w[nitro-kit-hotwire nitro-kit-rails nitro-kit-ui].freeze
    SKILL_ROOTS = [ ".agents/skills", ".claude/skills" ].freeze
    MANAGED_STYLESHEETS = %w[
      lexxy nitro_kit-tailwind-v4 nitro_kit tailwind application
    ].freeze
    AGENTS_START = "<!-- nitro-kit:start -->"
    AGENTS_END = "<!-- nitro-kit:end -->"
    AGENTS_BLOCK = <<~MARKDOWN.freeze
      #{AGENTS_START}
      ## Nitro Kit 2

      This application uses Nitro Kit 2.x. Before changing Rails structure,
      Hotwire interactions, or UI, use the matching project-local Nitro Kit skill.
      Each skill resolves the installed gem with `bundle show nitro_kit` and reads
      its version-matched documentation.

      In a greenfield application, run `bin/rails generate phlex:install` and use
      Phlex for the application layout, route views, and reusable UI. In an
      established application, preserve its existing view architecture and
      introduce Phlex and Nitro Kit only at the requested boundary unless an
      application-wide migration is explicitly authorized.

      Do not use Nitro Kit 1.x APIs, `nk_*` helpers, copied Nitro components, or
      application-owned `controllers/nk`. Include `NitroKit` once in the base Phlex
      component and prefer capitalized Kit methods such as `Button(...)` and
      `Card(...)`; use `.new` only when another API requires a component object.
      Keep routes, records, authorization, queries, DOM IDs, and server responses
      in the application.

      During migration, replace an existing form control only when Nitro Kit 2 has
      a genuine semantic and behavioral equivalent. Otherwise preserve the control
      as application-owned Rails and semantic HTML. Never downgrade specialized
      behavior or retain copied Nitro Kit 1.x source as the fallback.
      #{AGENTS_END}
    MARKDOWN

    Check = Struct.new(:status, :label, :detail, keyword_init: true)
    LayoutExpression = Struct.new(:range, :type, :assets, :dynamic, keyword_init: true)
    LayoutAnalysis = Struct.new(:head_range, :stylesheets, :bootstraps, :errors, keyword_init: true)

    attr_reader :application_root

    def initialize(application_root)
      @application_root = Pathname.new(application_root)
    end

    def install
      changes = { "AGENTS.md" => write_agents }.merge(write_skills)
      changes[relative(layout_path)] = write_layout if layout_path
      changes
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
        stylesheet_setup_check,
        phlex_kit_check,
        *migration_checks
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
        javascript = application_root.glob("app/javascript/**/*.{js,ts}").select(&:file?).map(&:read)
        loader = if javascript.any? { _1.include?("eagerLoadControllersFrom") }
          "eager controller loading"
        elsif javascript.any? { _1.match?(/\bapplication\.register\s*\(/) }
          "explicit controller registration"
        end

        Check.new(
          status: loader ? :pass : :warn,
          label: "Stimulus loader",
          detail: loader ? "#{loader} is configured" : "verify the application's controller registration"
        )
      end

      def stylesheet_setup_check
        return Check.new(
          status: :fail,
          label: "Stylesheet and appearance setup",
          detail: "missing application layout; add AppearanceBootstrap before the ordered stylesheet entries"
        ) unless layout_path

        contents = layout_path.read
        analysis = analyze_layout(contents)
        expected = expected_stylesheets(analysis)
        errors = []
        bootstrap_count = analysis.bootstraps.size

        if analysis.errors.any?
          return Check.new(
            status: :fail,
            label: "Stylesheet and appearance setup",
            detail: "#{relative(layout_path)}: installer left the layout unchanged — #{analysis.errors.join('; ')}; manually ensure AppearanceBootstrap → #{expected.join(' → ')} without discarding existing options"
          )
        end

        errors << "add one NitroKit::AppearanceBootstrap before every stylesheet" if bootstrap_count.zero?
        errors << "remove duplicate NitroKit::AppearanceBootstrap entries" if bootstrap_count > 1

        assets = managed_stylesheet_assets(analysis)
        expected.each do |stylesheet|
          count = assets.count(stylesheet)
          errors << "add stylesheet #{stylesheet.inspect}" if count.zero?
          errors << "remove duplicate stylesheet #{stylesheet.inspect}" if count > 1
        end

        if (edit_error = layout_edit_error(analysis, expected))
          errors << "installer left the layout unchanged: #{edit_error}"
        end

        if assets.include?("nitro_kit-tailwind-v4") && !expected.include?("tailwind")
          errors << "remove nitro_kit-tailwind-v4 or load compiled Tailwind after nitro_kit"
        end

        bootstrap_position = analysis.bootstraps.first&.range&.begin
        first_stylesheet_position = analysis.stylesheets.first&.range&.begin
        if errors.empty? && (bootstrap_position >= first_stylesheet_position || assets != expected)
          errors << "reorder to AppearanceBootstrap → #{expected.join(' → ')}"
        end

        Check.new(
          status: errors.empty? ? :pass : :fail,
          label: "Stylesheet and appearance setup",
          detail: errors.empty? ? "#{relative(layout_path)}: AppearanceBootstrap → #{expected.join(' → ')}" : "#{relative(layout_path)}: #{errors.join('; ')}"
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

      def migration_checks
        MigrationInventory.new(application_root).categories.map do |label, findings|
          Check.new(
            status: findings.empty? ? :pass : :warn,
            label: "Migration: #{label}",
            detail: findings.empty? ? "migrated: none found" : findings.map do |finding|
              "#{finding.status.to_s.tr('_', '-')}: #{finding.path} — #{finding.guidance}"
            end.join("\n")
          )
        end
      end

      def layout_path
        layout_paths.first
      end

      def layout_paths
        [
          application_root.join("app/components/ui/application_layout.rb"),
          application_root.join("app/components/application_layout.rb"),
          application_root.join("app/views/layouts/application.html.erb"),
          *application_root.glob("app/components/**/application_layout.rb")
        ].uniq.select(&:file?)
      end

      def write_layout
        write(layout_path, configured_layout(layout_path.read))
      end

      def configured_layout(contents)
        analysis = analyze_layout(contents)
        expected = expected_stylesheets(analysis)
        edit_error = layout_edit_error(analysis, expected)
        return contents if edit_error

        missing = expected - managed_stylesheet_assets(analysis)
        return contents if missing.empty? && analysis.bootstraps.one?

        lines = contents.lines
        insertions = Hash.new { |hash, index| hash[index] = [] }
        indent = layout_indent(lines, analysis)

        if analysis.bootstraps.empty?
          bootstrap_index = analysis.stylesheets.first&.range&.begin || analysis.head_range.begin + 1
          insertions[bootstrap_index] << bootstrap_markup(indent)
        end

        missing.group_by { insertion_slot(analysis, expected, _1) }.each do |slot, assets|
          index = stylesheet_insertion_index(analysis, slot)
          assets.sort_by { expected.index(_1) }.each do |asset|
            insertions[index] << stylesheet_markup(indent, asset)
          end
        end

        (0..lines.length).each_with_object(String.new) do |index, updated|
          insertions[index].each { updated << _1 }
          updated << lines[index] if index < lines.length
        end
      end

      def analyze_layout(contents)
        errors = []
        errors << "multiple application layouts found: #{layout_paths.map { relative(_1) }.join(', ')}" if layout_paths.many?
        lines = contents.lines
        head_range, boundary_errors = if layout_path.extname == ".rb"
          phlex_head_range(contents)
        else
          erb_head_range(contents)
        end
        errors.concat(boundary_errors)

        all_expressions = layout_path.extname == ".rb" ? phlex_layout_expressions(contents) : erb_layout_expressions(contents)
        expressions = if head_range
          all_expressions.select do |expression|
            inside = head_range.cover?(expression.range.begin) && head_range.cover?(expression.range.end)
            overlaps = head_range.cover?(expression.range.begin) || head_range.cover?(expression.range.end)
            errors << "#{expression.type} call on line #{expression.range.begin + 1} crosses the document head boundary" if overlaps && !inside
            inside
          end
        else
          []
        end
        outside_expressions = all_expressions - expressions
        outside_expressions.each do |expression|
          next if head_range && (head_range.cover?(expression.range.begin) || head_range.cover?(expression.range.end))

          errors << "#{expression.type} call on line #{expression.range.begin + 1} is outside the document head"
        end

        stylesheets = expressions.select { _1.type == :stylesheet }
        bootstraps = expressions.select { _1.type == :bootstrap }
        target_indent = head_range ? lines[head_range.begin][/^\s*/].to_s.length + 2 : nil

        expressions.each do |expression|
          actual_indent = lines[expression.range.begin][/^\s*/].to_s.length
          errors << "#{expression.type} call on line #{expression.range.begin + 1} is conditional or nested" unless actual_indent == target_indent
        end
        stylesheets.each do |expression|
          errors << "stylesheet call on line #{expression.range.begin + 1} has dynamic assets" if expression.dynamic
          if (expression.assets & MANAGED_STYLESHEETS).any? && (expression.assets - MANAGED_STYLESHEETS).any?
            errors << "stylesheet call on line #{expression.range.begin + 1} combines custom and canonical assets"
          end
        end

        head_contents = head_range ? lines[head_range].join : ""
        if layout_path.extname == ".erb" && head_contents.match?(/<%(?![=%#])/)
          errors << "head contains conditional or executable ERB"
        end
        if head_contents.match?(/<link\b[^>]*\brel=["']stylesheet["']/i)
          errors << "head contains a custom stylesheet link"
        end

        LayoutAnalysis.new(head_range: head_range || (0..0), stylesheets:, bootstraps:, errors: errors.uniq)
      end

      def erb_head_range(contents)
        lines = contents.lines
        starts = lines.each_index.select { lines[_1].match?(/^\s*<head(?:\s[^>]*)?>\s*$/i) }
        finishes = lines.each_index.select { lines[_1].match?(/^\s*<\/head>\s*$/i) }
        errors = []
        errors << "expected one conventional <head> opening tag on its own line" unless starts.one?
        errors << "expected one conventional </head> closing tag on its own line" unless finishes.one?
        return [ nil, errors ] unless starts.one? && finishes.one?

        errors << "the </head> closing tag must follow the <head> opening tag" unless starts.first < finishes.first
        [ starts.first..finishes.first, errors ]
      end

      def phlex_head_range(contents)
        syntax = Ripper.sexp(contents)
        return [ nil, [ "could not parse the Phlex application layout" ] ] unless syntax

        html_blocks = ruby_block_calls(syntax, "html")
        head_blocks = ruby_block_calls(syntax, "head")
        errors = []
        errors << "expected one conventional html block in the Phlex application layout" unless html_blocks.one?
        errors << "expected one conventional head block in the Phlex application layout" unless head_blocks.one?
        return [ nil, errors ] unless html_blocks.one? && head_blocks.one?

        html_statements = ruby_block_statements(html_blocks.first)
        direct_heads = html_statements.select { ruby_block_call_name(_1) == "head" }
        unless direct_heads.one? && direct_heads.first.equal?(head_blocks.first)
          return [ nil, [ "the Phlex head block must be owned directly by the conventional html block" ] ]
        end

        position = ruby_node_position(head_blocks.first, "head")
        return [ nil, [ "could not determine the Phlex head block boundary" ] ] unless position

        start = position.first - 1
        indent = lines_indent(contents.lines[start])
        unless contents.lines[start].match?(/^#{Regexp.escape(indent)}head(?:\(\s*\))?\s+do\s*$/)
          return [ nil, [ "the Phlex head block must use a conventional `head do` line" ] ]
        end

        head_statement_index = html_statements.index { _1.equal?(head_blocks.first) }
        next_statement_position = html_statements[(head_statement_index + 1)..].filter_map { ruby_first_position(_1) }.min
        upper_bound = if next_statement_position
          next_statement_position.first - 2
        else
          html_position = ruby_node_position(html_blocks.first, "html")
          html_indent = lines_indent(contents.lines[html_position.first - 1])
          contents.lines.each_index.find do |index|
            index > start && contents.lines[index].match?(/^#{Regexp.escape(html_indent)}end\s*$/)
          end
        end
        return [ nil, [ "could not determine the closing `end` for the Phlex html block" ] ] unless upper_bound

        finishes = contents.lines.each_index.select do |index|
          index > start && index <= upper_bound && contents.lines[index].match?(/^#{Regexp.escape(indent)}end\s*$/)
        end
        unless finishes.one?
          return [ nil, [ "could not uniquely determine the closing `end` for the Phlex head block" ] ]
        end

        [ start..finishes.first, errors ]
      end

      def phlex_layout_expressions(contents)
        lines = contents.lines
        Ripper.lex(contents).filter_map do |(position, event, token, _state)|
          next unless event == :on_ident && token == "stylesheet_link_tag"

          start = position.first - 1
          range = ruby_expression_range(lines, start)
          source = lines[range].join
          assets = static_stylesheet_assets(source)
          LayoutExpression.new(range:, type: :stylesheet, assets: assets || [], dynamic: assets.nil?)
        end + lines.each_index.filter_map do |index|
          range = ruby_expression_range(lines, index)
          source = lines[range].join
          next unless source.lstrip.start_with?("render") && bootstrap_expression?(source)

          LayoutExpression.new(range:, type: :bootstrap, assets: [], dynamic: false)
        end.uniq { [ _1.type, _1.range ] }.sort_by { _1.range.begin }
      end

      def erb_layout_expressions(contents)
        contents.to_enum(:scan, /<%=(.*?)%>/m).filter_map do
          match = Regexp.last_match
          start = contents[0...match.begin(0)].count("\n")
          finish = contents[0...match.end(0)].count("\n")
          source = match[1]
          if ruby_identifier?(source, "stylesheet_link_tag")
            assets = static_stylesheet_assets(source)
            LayoutExpression.new(range: start..finish, type: :stylesheet, assets: assets || [], dynamic: assets.nil?)
          elsif bootstrap_expression?(source)
            LayoutExpression.new(range: start..finish, type: :bootstrap, assets: [], dynamic: false)
          end
        end.sort_by { _1.range.begin }
      end

      def ruby_expression_range(lines, start)
        (start...lines.length).each do |finish|
          return start..finish if Ripper.sexp(lines[start..finish].join)
        end
        start..start
      end

      def static_stylesheet_assets(source)
        arguments = invocation_arguments(Ripper.sexp(source), "stylesheet_link_tag")
        return unless arguments

        positional = arguments.take_while { !%i[bare_assoc_hash hash].include?(_1&.first) }
        return unless arguments.drop(positional.length).all? { %i[bare_assoc_hash hash].include?(_1&.first) }

        positional.map { string_literal(_1) }.tap { return if _1.any?(&:nil?) }
      end

      def invocation_arguments(node, name)
        return unless node.is_a?(Array)

        arguments = direct_invocation_arguments(node, name)
        return arguments if arguments

        node.filter_map { invocation_arguments(_1, name) if _1.is_a?(Array) }.first
      end

      def invocation_argument_lists(node, name)
        return [] unless node.is_a?(Array)

        arguments = direct_invocation_arguments(node, name)
        nested = node.flat_map { invocation_argument_lists(_1, name) if _1.is_a?(Array) }.compact
        arguments ? [ arguments, *nested ] : nested
      end

      def direct_invocation_arguments(node, name)
        case node.first
        when :method_add_arg
          argument_list(node[2]) if callable_name(node[1]) == name
        when :command
          argument_list(node[2]) if node.dig(1, 1) == name
        end
      end

      def callable_name(node)
        node.dig(1, 1) if node&.first == :fcall
      end

      def ruby_block_calls(node, name)
        return [] unless node.is_a?(Array)

        calls = ruby_block_call_name(node) == name ? [ node ] : []
        calls + node.flat_map { ruby_block_calls(_1, name) if _1.is_a?(Array) }.compact
      end

      def ruby_block_call_name(node)
        return unless node&.first == :method_add_block

        call = node[1]
        case call&.first
        when :method_add_arg
          callable_name(call[1])
        when :command
          call.dig(1, 1)
        end
      end

      def ruby_block_statements(node)
        block = node[2]
        block&.first == :do_block && block.dig(2, 1) || []
      end

      def ruby_node_position(node, name)
        return unless node.is_a?(Array)
        return node[2] if node.first == :@ident && node[1] == name

        node.filter_map { ruby_node_position(_1, name) if _1.is_a?(Array) }.first
      end

      def ruby_first_position(node)
        return unless node.is_a?(Array)
        return node[2] if node.first.to_s.start_with?("@") && node[2].is_a?(Array)

        node.filter_map { ruby_first_position(_1) if _1.is_a?(Array) }.min
      end

      def lines_indent(line)
        line[/^\s*/].to_s
      end

      def argument_list(node)
        node = node[1] if node&.first == :arg_paren
        node&.first == :args_add_block ? node[1] : nil
      end

      def string_literal(node)
        return unless node&.first == :string_literal
        return "" if node[1]&.first == :string_content && node[1].length == 1
        return unless node[1]&.first == :string_content && node[1][1..].all? { _1.first == :@tstring_content }

        node[1][1..].map { _1[1] }.join
      end

      def bootstrap_expression?(source)
        tokens = Ripper.lex(source).reject { %i[on_sp on_nl on_ignored_nl].include?(_1[1]) }.map { _1[2] }
        tokens.each_cons(3).any? { _1 == [ "NitroKit", "::", "AppearanceBootstrap" ] }
      end

      def ruby_identifier?(source, identifier)
        Ripper.lex(source).any? { _1[1] == :on_ident && _1[2] == identifier }
      end

      def expected_stylesheets(analysis)
        assets = managed_stylesheet_assets(analysis) - [ "nitro_kit-tailwind-v4" ]
        assets << "lexxy" if dependency?("lexxy")
        assets << "tailwind" if tailwind?(assets)
        assets << "nitro_kit"
        assets << "application" if assets.include?("application") || application_stylesheet_asset?
        assets << "nitro_kit-tailwind-v4" if assets.include?("tailwind")
        ordered_stylesheets(assets.uniq)
      end

      def ordered_stylesheets(assets)
        vendor = assets - %w[nitro_kit-tailwind-v4 nitro_kit tailwind application]
        [
          *vendor,
          *(%w[nitro_kit-tailwind-v4] & assets),
          *(%w[nitro_kit] & assets),
          *(%w[tailwind] & assets),
          *(%w[application] & assets)
        ]
      end

      def layout_edit_error(analysis, expected)
        return analysis.errors.join("; ") if analysis.errors.any?
        return "duplicate AppearanceBootstrap calls require manual review" if analysis.bootstraps.many?

        first_stylesheet = analysis.stylesheets.first
        if analysis.bootstraps.one? && first_stylesheet && analysis.bootstraps.first.range.begin > first_stylesheet.range.begin
          return "AppearanceBootstrap is after a stylesheet; move the existing call without changing its options"
        end

        existing = managed_stylesheet_assets(analysis)
        return "duplicate canonical stylesheet assets require manual review" if existing.uniq != existing
        unless existing == expected.select { existing.include?(_1) }
          return "existing canonical stylesheets are misordered; reorder their intact calls manually"
        end

        missing = expected - existing
        if missing.any? { insertion_slot(analysis, expected, _1).nil? }
          "a combined stylesheet call spans a required insertion point; split it without changing its options, then rerun the installer"
        end
      end

      def insertion_slot(analysis, expected, asset)
        rank = expected.index(asset)
        managed = analysis.stylesheets.select { (_1.assets & MANAGED_STYLESHEETS).any? }
        lower = managed.each_index.filter_map do |index|
          index + 1 if managed[index].assets.any? { expected.index(_1).to_i < rank }
        end.max || 0
        upper = managed.each_index.filter_map do |index|
          index if managed[index].assets.any? { expected.index(_1).to_i > rank }
        end.min || managed.length
        lower if lower <= upper
      end

      def stylesheet_insertion_index(analysis, slot)
        managed = analysis.stylesheets.select { (_1.assets & MANAGED_STYLESHEETS).any? }
        if managed.empty?
          anchor = analysis.stylesheets.last || analysis.bootstraps.first
          anchor ? anchor.range.end + 1 : analysis.head_range.begin + 1
        elsif slot < managed.length
          managed[slot].range.begin
        else
          managed.last.range.end + 1
        end
      end

      def layout_indent(lines, analysis)
        expression = (analysis.stylesheets + analysis.bootstraps).min_by { _1.range.begin }
        expression ? lines[expression.range.begin][/^\s*/] : "#{lines[analysis.head_range.begin][/^\s*/]}  "
      end

      def bootstrap_markup(indent)
        if layout_path.extname == ".rb"
          "#{indent}render NitroKit::AppearanceBootstrap.new\n"
        else
          "#{indent}<%= render NitroKit::AppearanceBootstrap.new %>\n"
        end
      end

      def stylesheet_markup(indent, asset)
        if layout_path.extname == ".rb"
          "#{indent}stylesheet_link_tag(#{asset.inspect}, data: { turbo_track: \"reload\" })\n"
        else
          "#{indent}<%= stylesheet_link_tag #{asset.inspect}, \"data-turbo-track\": \"reload\" %>\n"
        end
      end

      def managed_stylesheet_assets(analysis)
        analysis.stylesheets.flat_map(&:assets).select { MANAGED_STYLESHEETS.include?(_1) }
      end

      def tailwind?(assets)
        assets.include?("tailwind") || dependency?("tailwindcss-rails") || application_root.join("app/assets/tailwind/application.css").file?
      end

      def application_stylesheet_asset?
        application_root.glob("app/assets/stylesheets/application.*").any?(&:file?) ||
          application_root.join("app/assets/builds/application.css").file?
      end

      def dependency?(name)
        gemfile = application_root.join("Gemfile")
        return false unless gemfile.file?

        syntax = Ripper.sexp(gemfile.read)
        syntax && invocation_argument_lists(syntax, "gem").any? { string_literal(_1.first) == name }
      end

      def relative(path)
        path.relative_path_from(application_root).to_s
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
