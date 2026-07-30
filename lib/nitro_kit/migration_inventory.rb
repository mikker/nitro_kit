require "pathname"
require "ripper"

module NitroKit
  class MigrationInventory
    Finding = Struct.new(:status, :path, :guidance, keyword_init: true)

    LEGACY_COMPONENTS = %w[
      accordion alert avatar avatar_stack badge button button_group card checkbox
      checkbox_group combobox component datepicker dialog dropdown field field_group
      fieldset form_builder icon input label pagination radio_button radio_button_group
      select switch table tabs textarea toast tooltip
    ].freeze
    LEGACY_CONTROLLERS = %w[
      accordion combobox datepicker dialog dropdown switch tabs toast tooltip
    ].freeze
    HELPER_REPLACEMENTS = {
      "nk_button_link_to" => "replace with Button(..., href:)",
      "nk_button_to" => "replace with ButtonTo(..., href:, method:)",
      "nk_form_with" => "replace with Rails form_with(..., builder: NitroKit::FormBuilder)",
      "nk_form_for" => "replace with Rails form_with(..., builder: NitroKit::FormBuilder)",
      "nk_pagy_nav" => "replace with Pagination(pagy:)",
      "nk_toast_flash_messages" => "replace with NitroKit::Toast::FlashMessages",
      "nk_toast_turbo_stream_refresh" => "append NitroKit::Toast::Item to the toast list",
      "nk_toast_action" => "replace the client toast action with Rails flash or a rendered Toast::Item",
      "nk_checkbox_tag" => "replace with Checkbox(...) and preserve the submitted name and values",
      "nk_check_box_tag" => "replace with Checkbox(...) and preserve the submitted name and values"
    }.freeze
    DIRECT_HELPERS = %w[
      accordion alert avatar avatar_stack badge button button_group card checkbox
      checkbox_group combobox dialog dropdown field field_group fieldset icon input
      label pagination radio_button radio_button_group select switch table tabs textarea
      toast tooltip
    ].freeze
    FIELD_TAG_REPLACEMENTS = {
      "color" => :color,
      "date" => :date,
      "datetime" => :"datetime-local",
      "datetime_local" => :"datetime-local",
      "email" => :email,
      "file" => :file,
      "hidden" => :hidden,
      "month" => :month,
      "number" => :number,
      "password" => :password,
      "phone" => :tel,
      "range" => :range,
      "search" => :search,
      "telephone" => :tel,
      "text" => :text,
      "time" => :time,
      "url" => :url,
      "week" => :week
    }.transform_keys { "nk_#{_1}_field_tag" }.freeze
    VENDORED_MODULES = {
      "@floating-ui/core" => "remove the 1.x Floating UI pin or package after copied controllers are removed",
      "@floating-ui/dom" => "remove the 1.x Floating UI pin or package after copied controllers are removed",
      "@floating-ui/utils" => "remove the 1.x Floating UI pin or package after copied controllers are removed",
      "@github/combobox-nav" => "remove the 1.x combobox package; Nitro Kit 2 owns combobox behavior"
    }.freeze

    attr_reader :application_root

    def initialize(application_root)
      @application_root = Pathname.new(application_root)
    end

    def categories
      {
        "Legacy helpers" => legacy_helpers,
        "Copied or shadow components" => copied_components,
        "Custom or legacy controllers" => controllers,
        "Vendored dependencies" => vendored_dependencies,
        "Known replacements" => replacement_summary,
        "Unresolved or application-owned items" => disposition_summary
      }
    end

    private
      def legacy_helpers
        @legacy_helpers ||= source_files.flat_map do |path|
          helper_identifiers(path).filter_map do |helper, line_number|
            next unless legacy_helper?(helper)

            Finding.new(
              status: helper == "nk_datepicker" ? :application_owned : :unresolved,
              path: location(path, line_number),
              guidance: helper_guidance(helper)
            )
          end
        end.uniq { [ _1.status, _1.path, _1.guidance ] }
      end

      def copied_components
        application_root.glob("app/components/nitro_kit/**/*.rb").map do |path|
          name = path.basename(".rb").to_s
          known = legacy_component?(path, name)

          Finding.new(
            status: known && name != "datepicker" ? :unresolved : :application_owned,
            path: relative(path),
            guidance: component_guidance(name, known:)
          )
        end
      end

      def controllers
        application_root.glob("app/javascript/controllers/nk/**/*_controller.js").map do |path|
          name = path.basename("_controller.js").to_s
          expected_path = "app/javascript/controllers/nk/#{name}_controller.js"
          known = LEGACY_CONTROLLERS.include?(name) && relative(path) == expected_path

          Finding.new(
            status: known && name != "datepicker" ? :unresolved : :application_owned,
            path: relative(path),
            guidance: controller_guidance(name, known:)
          )
        end
      end

      def vendored_dependencies
        findings = application_root.glob("vendor/javascript/{@floating-ui--*,@github--combobox-nav*}.js").map do |path|
          Finding.new(
            status: :unresolved,
            path: relative(path),
            guidance: "delete the vendored 1.x runtime after removing copied Nitro controllers"
          )
        end

        dependency_files.each do |path|
          path.each_line.with_index(1) do |line, line_number|
            next if line.lstrip.start_with?("#", "//")

            VENDORED_MODULES.each do |name, guidance|
              findings << Finding.new(status: :unresolved, path: location(path, line_number), guidance:) if line.include?(name)
            end
            if line.match?(/\btailwind_merge\b/)
              findings << Finding.new(
                status: :unresolved,
                path: location(path, line_number),
                guidance: "remove tailwind_merge; Nitro Kit 2 ships static CSS and does not use it"
              )
            end
          end
        end

        findings.uniq { [ _1.path, _1.guidance ] }
      end

      def replacement_summary
        unresolved_findings.group_by(&:guidance).map do |guidance, findings|
          Finding.new(
            status: :unresolved,
            path: "#{findings.size} occurrence#{"s" unless findings.one?}",
            guidance:
          )
        end
      end

      def disposition_summary
        all_findings.group_by(&:status).map do |status, findings|
          guidance = case status
          when :application_owned
            "preserve the behavior under an application namespace; do not keep a Nitro shadow"
          else
            "apply the per-file replacement or removal listed in the category above"
          end
          Finding.new(
            status:,
            path: "#{findings.size} finding#{"s" unless findings.one?}",
            guidance:
          )
        end
      end

      def unresolved_findings
        all_findings.select { _1.status == :unresolved }
      end

      def all_findings
        @all_findings ||= (legacy_helpers + copied_components + controllers + vendored_dependencies)
          .uniq { [ _1.status, _1.path, _1.guidance ] }
      end

      def source_files
        application_root.glob("app/**/*.{rb,erb,haml,slim}").select(&:file?)
      end

      def dependency_files
        files = %w[Gemfile config/importmap.rb package.json].filter_map do |name|
          path = application_root.join(name)
          path if path.file?
        end
        files + application_root.glob("app/javascript/controllers/nk/**/*.js")
      end

      def helper_identifiers(path)
        case path.extname
        when ".rb"
          ruby_identifiers(path.read)
        when ".erb"
          erb_identifiers(path.read)
        when ".haml", ".slim"
          template_line_identifiers(path.read)
        else
          []
        end
      end

      def ruby_identifiers(source, line_offset = 0)
        tokens = Ripper.lex(source)
        tokens.each_index.filter_map do |index|
          position, event, token, = tokens[index]
          next unless event == :on_ident && token.start_with?("nk_")

          previous = tokens[0...index].reverse.find { !%i[on_sp on_nl on_ignored_nl].include?(_1[1]) }
          [ token, position.first + line_offset ] unless previous&.at(1) == :on_symbeg
        end
      end

      def erb_identifiers(source)
        source.to_enum(:scan, /<%(?!%|#)[=-]?(.*?)%>/m).flat_map do
          match = Regexp.last_match
          line_offset = source[0...match.begin(1)].count("\n")
          ruby_identifiers(match[1], line_offset)
        end
      end

      def template_line_identifiers(source)
        source.each_line.with_index(1).flat_map do |line, line_number|
          code = line.lstrip
          next [] unless code.start_with?("=", "-") && !code.start_with?("-#")

          ruby_identifiers(code.delete_prefix(code[0]), line_number - 1)
        end
      end

      def legacy_component?(path, name)
        return false unless LEGACY_COMPONENTS.include?(name)
        return false unless relative(path) == "app/components/nitro_kit/#{name}.rb"

        declared_constants(path.read).include?("NitroKit::#{camelize(name)}")
      end

      def declared_constants(source)
        constants = []
        walk_constants(Ripper.sexp(source), nil, constants)
        constants
      end

      def walk_constants(node, namespace, constants)
        return unless node.is_a?(Array)

        if %i[module class].include?(node.first)
          name = constant_name(node[1])
          if name
            full_name = name.include?("::") || namespace.nil? ? name : "#{namespace}::#{name}"
            constants << full_name
            walk_constants(node[node.first == :class ? 3 : 2], full_name, constants)
            return
          end
        end

        node.each { walk_constants(_1, namespace, constants) if _1.is_a?(Array) }
      end

      def constant_name(node)
        return unless node.is_a?(Array)

        case node.first
        when :const_ref, :var_ref, :top_const_ref
          constant_name(node[1])
        when :const_path_ref
          [ constant_name(node[1]), constant_name(node[2]) ].compact.join("::")
        when :@const
          node[1]
        end
      end

      def legacy_helper?(helper)
        HELPER_REPLACEMENTS.key?(helper) || FIELD_TAG_REPLACEMENTS.key?(helper) || helper == "nk_datepicker" ||
          DIRECT_HELPERS.include?(helper.delete_prefix("nk_")) || automatic_variant_helper?(helper)
      end

      def automatic_variant_helper?(helper)
        helper.match?(/\Ank_[a-z0-9]+_(?:alert|badge|button|button_to|button_link_to)\z/)
      end

      def helper_guidance(helper)
        return HELPER_REPLACEMENTS.fetch(helper) if HELPER_REPLACEMENTS.key?(helper)
        if FIELD_TAG_REPLACEMENTS.key?(helper)
          type = FIELD_TAG_REPLACEMENTS.fetch(helper).inspect
          return "replace with Input(type: #{type}) and preserve the submitted name and value"
        end
        if helper == "nk_datepicker"
          return "use Input(type: :date) only when native date semantics are equivalent; otherwise preserve the behavior in an application-owned component"
        end

        if helper.end_with?("_button_link_to")
          return "replace #{helper} with Button(..., href:) and pass the old variant explicitly"
        end
        if helper.end_with?("_button_to")
          return "replace #{helper} with ButtonTo(..., href:, method:) and pass the old variant explicitly"
        end
        if automatic_variant_helper?(helper)
          component = helper.delete_prefix("nk_").sub(/\A[a-z0-9]+_/, "")
          return "replace #{helper} with direct Phlex #{camelize(component)}(...) and review the old variant against the current contract"
        end

        component = helper.delete_prefix("nk_")
        "replace #{helper} with direct Phlex #{camelize(component)}(...) composition"
      end

      def component_guidance(name, known:)
        if name == "component" && known
          "delete the copied base component; include NitroKit once in the application-owned Phlex base"
        elsif name == "form_builder" && known
          "delete the shadow and select the gem-owned NitroKit::FormBuilder through Rails form_with"
        elsif name == "datepicker" && known
          "remove the 1.x copy; use Input(type: :date) only when equivalent, otherwise rebuild it in the application namespace"
        elsif known
          "delete the shadow and compose the gem-owned NitroKit::#{camelize(name)}"
        else
          "move this customization out of NitroKit into the application namespace and compose public Nitro components"
        end
      end

      def controller_guidance(name, known:)
        if name == "datepicker" && known
          "remove the 1.x controller; keep specialized behavior only in an application-owned controller and component"
        elsif known
          "delete the 1.x controller and use the gem-owned Nitro behavior"
        else
          "move this custom behavior out of controllers/nk and register it under an application-owned identifier"
        end
      end

      def camelize(value)
        value.split("_").map(&:capitalize).join
      end

      def location(path, line_number)
        "#{relative(path)}:#{line_number}"
      end

      def relative(path)
        path.relative_path_from(application_root).to_s
      end
  end
end
