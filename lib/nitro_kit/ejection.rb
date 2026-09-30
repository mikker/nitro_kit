require "ripper"
require "json"
require "nitro_kit/version"

module NitroKit
  class Ejection
    ROOT = File.expand_path("../..", __dir__)
    SUPPORT_FILES = %w[component layout_options responsive_value].freeze

    def initialize(name)
      @name = name.delete_prefix("NitroKit::").underscore
      @sources = Dir["#{ROOT}/app/components/nitro_kit/*.rb"].to_h do |path|
        [ File.basename(path, ".rb").camelize, File.read(path) ]
      end
      unless @sources.key?(component_name) && !SUPPORT_FILES.include?(@name)
        raise ArgumentError, "Unknown component #{name.inspect}. Choose one of: #{(@sources.keys - SUPPORT_FILES.map(&:camelize)).sort.join(', ')}"
      end
    end

    def component_name = @name.camelize
    def stylesheet_name = "ejected_#{@name}"
    def namespace = directory.camelize
    def prefix = "ui-ejected-#{@name.dasherize}"
    def directory = "ui/ejected_#{@name}"

    def files
      result = {}
      ruby_names.each do |name|
        result["app/components/#{directory}/#{name.underscore}.rb"] = header("#") + rewrite_ruby(@sources.fetch(name))
      end
      result["app/components/#{directory}/component.rb"] = header("#") + component_adapter
      result["app/assets/stylesheets/#{stylesheet_name}.css"] = header("/*", " */") + stylesheet
      javascript_paths.each do |path|
        relative = path.delete_prefix("#{ROOT}/app/javascript/controllers/nk/")
        source = rewrite_contracts(File.read(path))
          .gsub("controllers/nk/", "controllers/#{directory}/")
        result["app/javascript/controllers/#{directory}/#{relative}"] = header("//") + source
      end
      result["config/nitro_kit/ejected/#{@name}.json"] = JSON.pretty_generate(
        component: component_name, version: VERSION, namespace:, files: result.keys
      ) + "\n"
      result
    end

    private
      def header(open, close = "")
        "#{open} Ejected from Nitro Kit #{VERSION}: #{component_name}. Application-owned; not automatically upgraded.#{close}\n"
      end

      def ruby_names
        @ruby_names ||= begin
          names = [ component_name ]
          names.each do |name|
            Ripper.lex(@sources.fetch(name)).each do |_, type, token, _|
              names << token if type == :on_const && @sources.key?(token) && token != "Component" && !names.include?(token)
            end
          end
          names
        end
      end

      def stylesheet
        names = ruby_names.map(&:underscore)
        names << "palette" if (ruby_names & %w[Badge Alert Toast]).any?
        names << "layout" if (ruby_names & %w[Flex Grid]).any?
        rules = names.filter_map do |name|
          path = "#{ROOT}/src/stylesheets/nitro_kit/components/#{name}.css"
          rewrite_contracts(File.read(path)) if File.file?(path)
        end
        layers = %w[base variant size state compound].map { |layer| "#{prefix}.#{layer}" }.join(", ")
        "@layer #{layers};\n" + rules.join("\n")
      end

      def javascript_paths
        ruby_source = ruby_names.map { |name| @sources.fetch(name) }.join("\n")
        paths = Dir["#{ROOT}/app/javascript/controllers/nk/*_controller.js"].select do |path|
          name = File.basename(path, "_controller.js")
          ruby_source.include?("nk--#{name.dasherize}") || ruby_source.include?("nk__#{name}")
        end
        # Shared overlay command plumbing lives in the component adapter.
        paths |= [ "#{ROOT}/app/javascript/controllers/nk/dialog_controller.js" ] if ruby_source.include?("command_data(")
        paths.each do |path|
          File.read(path).scan(/(?:from\s*|import\s*)["']([^"']+)["']/).flatten.each do |import|
            dependency = if import.start_with?("controllers/nk/")
              "#{ROOT}/app/javascript/#{import}.js"
            elsif import.start_with?(".")
              File.expand_path(import.end_with?(".js") ? import : "#{import}.js", File.dirname(path))
            end
            paths << dependency if dependency && File.file?(dependency) && !paths.include?(dependency)
          end
        end
        paths
      end

      def rewrite_ruby(source)
        rewrite_contracts(source.gsub("module NitroKit", "module #{namespace}").gsub("NitroKit::", "#{namespace}::"))
      end

      def rewrite_contracts(source)
        source.gsub("nk--", "ui--ejected-#{@name.dasherize}--")
          .gsub("nk__", "ui__ejected_#{@name}__")
          .gsub(/(data-(?:nk|slot)(?:[~|^$*]?=)["'])([^"']+)/) { "#{$1}#{prefix}-#{$2}" }
          .gsub(/(dataset\.slot\s*=\s*["'])([^"']+)/) { "#{$1}#{prefix}-#{$2}" }
          .gsub("--_nk-", "--_#{prefix}-")
          .gsub(/(?<![-\w])nk-(?!-)[a-z][a-z0-9-]*/) { |name| "#{prefix}-#{name.delete_prefix('nk-')}" }
          .gsub("nitro-kit.", "#{prefix}.")
      end

      def component_adapter
        # Copy component helpers, not the attribute kernel or the enclosing class.
        helpers = @sources.fetch("Component").lines
          .drop_while { |line| !line.start_with?("    def description_id") }[...-2].join
        <<~RUBY
          module #{namespace}
            class Component < NitroKit::Component
              def initialize(component:, **attributes)
                super(component: "#{prefix}-\#{component.to_s.tr('_', '-')}", **attributes)
              end

              private

              def qualified_slot(slot)
                name = slot.to_s.tr("_", "-")
                original = @component_name.delete_prefix("#{prefix}-")
                name = name.delete_prefix("\#{original}-")
                "\#{@component_name}-\#{name}"
              end

              # Snapshot of component-level helpers; attribute/render kernel stays gem-owned.
          #{rewrite_contracts(helpers)}
            end
          end
        RUBY
      end
  end
end
