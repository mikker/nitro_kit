require "pathname"
require "prism"
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
    DIRECT_HELPERS = (LEGACY_COMPONENTS - %w[component datepicker form_builder]).freeze
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
    BUTTON_TREATMENT_DEFINITION = /@utility\s+btn\b|\.btn(?:\s|[,{.:])/.freeze
    BUTTON_CLASS = /(?<![a-z0-9_-])btn(?:-[a-z0-9_-]+)?(?![a-z0-9_-])/i.freeze
    ERB_TAG_PATTERN = /<%(?!%|#)(==|[-=])?(.*?)(?:-)?%>/m
    TABLE_COMPOUND_KEYWORDS = {
      caption: %i[html aria data desperately_need_a_class],
      thead: %i[html aria data desperately_need_a_class],
      tbody: %i[html aria data desperately_need_a_class],
      tr: %i[html aria data desperately_need_a_class],
      th: %i[align scope sort href sort_data html aria data desperately_need_a_class],
      td: %i[align html aria data desperately_need_a_class]
    }.freeze

    class ContractVisitor < Prism::Visitor
      private
        def positional_arguments(node)
          Array(node.arguments&.arguments).reject { _1.is_a?(Prism::KeywordHashNode) }
        end

        def keyword_names(node)
          Array(node.arguments&.arguments).grep(Prism::KeywordHashNode).flat_map(&:elements).filter_map do |element|
            element.key.unescaped.to_sym if element.is_a?(Prism::AssocNode) && element.key.is_a?(Prism::SymbolNode)
          end
        end

        def dynamic_arguments?(node)
          Array(node.arguments&.arguments).any? do |argument|
            argument.is_a?(Prism::SplatNode) || argument.is_a?(Prism::BlockArgumentNode) ||
              (argument.is_a?(Prism::KeywordHashNode) && argument.elements.any? { _1.is_a?(Prism::AssocSplatNode) })
          end
        end

        def table_keyword_issues(node)
          allowed = TABLE_COMPOUND_KEYWORDS[node.name]
          return [] unless allowed

          (keyword_names(node) - allowed).map do |keyword|
            guidance = if keyword == :class
              "Table##{node.name} does not accept class: directly; move it to desperately_need_a_class:"
            elsif keyword == :style
              "Table##{node.name} does not allow style overrides; preserve this as application-owned HTML"
            else
              "Table##{node.name} does not accept #{keyword}: directly; move it to html: { #{keyword}: ... }"
            end
            RuntimeContractVisitor::Issue.new(line: node.location.start_line, guidance:)
          end
        end

        def receiver_named?(receiver, name)
          receiver.is_a?(Prism::LocalVariableReadNode) && receiver.name == name ||
            receiver.is_a?(Prism::CallNode) && receiver.receiver.nil? && receiver.name == name && receiver.arguments.nil?
        end
    end

    class RuntimeContractVisitor < ContractVisitor
      Issue = Data.define(:line, :guidance)

      attr_reader :issues

      def initialize
        @issues = []
      end

      def visit_call_node(node)
        inspect_button(node)
        inspect_table(node)
        inspect_table_local(node)
        inspect_icon_triggers(node)
        super
      end

      private
        def inspect_button(node)
          return unless node.name == :new && node.receiver&.respond_to?(:full_name)
          return unless node.receiver.full_name == "NitroKit::Button"
          return unless keyword_names(node).intersect?(%i[icon icon_end])
          return if positional_arguments(node).any? { !_1.is_a?(Prism::NilNode) }
          return if node.block || dynamic_arguments?(node)
          return if keyword_names(node).intersect?(%i[label aria])

          issues << Issue.new(
            line: node.location.start_line,
            guidance: "icon-only NitroKit::Button requires label:, aria: { label: ... }, or aria: { labelledby: ... }"
          )
        end

        def inspect_table(node)
          constructor = positional_arguments(node).first
          return unless node.name == :render && table_constructor?(constructor) && node.block

          parameter = node.block.parameters&.parameters&.requireds&.first
          return unless parameter.is_a?(Prism::RequiredParameterNode)
          return if parameter.name == :table

          visitor = TableCompoundVisitor.new(parameter.name)
          visitor.visit(node.block.body) if node.block.body
          issues.concat(visitor.issues)
        end

        def inspect_table_local(node)
          return unless receiver_named?(node.receiver, :table)

          issues.concat(table_keyword_issues(node))
        end

        def inspect_icon_triggers(node)
          constructor = positional_arguments(node).first
          return unless node.name == :render && node.block && constructor.is_a?(Prism::CallNode)
          return unless constructor.name == :new && constructor.receiver&.respond_to?(:full_name)

          component = constructor.receiver.full_name.delete_prefix("NitroKit::")
          return unless %w[Dropdown Sheet].include?(component)

          parameter = node.block.parameters&.parameters&.requireds&.first
          return unless parameter.is_a?(Prism::RequiredParameterNode)

          visitor = IconTriggerVisitor.new(parameter.name, component)
          visitor.visit(node.block.body) if node.block.body
          issues.concat(visitor.issues)
        end

        def table_constructor?(node)
          node.is_a?(Prism::CallNode) && node.name == :new &&
            node.receiver&.respond_to?(:full_name) && node.receiver.full_name == "NitroKit::Table"
        end
    end

    class IconTriggerVisitor < ContractVisitor
      attr_reader :issues

      def initialize(receiver_name, component)
        @receiver_name = receiver_name
        @component = component
        @issues = []
      end

      def visit_call_node(node)
        if unnamed_icon_trigger?(node)
          issues << RuntimeContractVisitor::Issue.new(
            line: node.location.start_line,
            guidance: "icon-only #{@component}#trigger requires label:, aria: { label: ... }, or aria: { labelledby: ... }"
          )
        end
        super
      end

      private
        def unnamed_icon_trigger?(node)
          return false unless node.name == :trigger
          return false unless node.receiver.is_a?(Prism::LocalVariableReadNode) && node.receiver.name == @receiver_name
          return false unless keyword_names(node).intersect?(%i[icon icon_end])
          return false if positional_arguments(node).any? { !_1.is_a?(Prism::NilNode) }
          return false if node.block || dynamic_arguments?(node)
          return false if keyword_names(node).intersect?(%i[label aria])

          true
        end
    end

    class TableCompoundVisitor < ContractVisitor
      attr_reader :issues

      def initialize(receiver_name)
        @receiver_name = receiver_name
        @issues = []
      end

      def visit_call_node(node)
        if receiver_named?(node.receiver, @receiver_name)
          issues.concat(table_keyword_issues(node))
        end
        super
      end
    end
    private_constant :ContractVisitor, :RuntimeContractVisitor, :IconTriggerVisitor, :TableCompoundVisitor

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
        "Application-owned button treatments" => application_button_treatments,
        "2.0 runtime contract errors" => runtime_contract_errors,
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
          end
        end

        findings.uniq { [ _1.path, _1.guidance ] }
      end

      def application_button_treatments
        return [] unless application_stylesheets.any? { _1.read.match?(BUTTON_TREATMENT_DEFINITION) }

        source_files.filter_map do |path|
          lines = path.each_line.with_index(1).filter_map do |line, line_number|
            next if line.lstrip.start_with?("#", "<%#")

            line_number if line.match?(BUTTON_CLASS)
          end
          next if lines.empty?

          Finding.new(
            status: :application_owned,
            path: "#{relative(path)}:#{lines.join(',')}",
            guidance: "review the application-owned button treatment; migrate ordinary actions to NitroKit::Button and preserve specialized controls as semantic application HTML"
          )
        end
      end

      def runtime_contract_errors
        source_files.flat_map do |path|
          source = runtime_ruby_source(path)
          next [] unless source

          result = Prism.parse(source)
          issues = if result.success?
            runtime_contract_issues(result.value)
          elsif path.extname == ".erb"
            erb_runtime_contract_issues(path.read)
          else
            []
          end
          issues.map do |issue|
            Finding.new(
              status: :unresolved,
              path: location(path, issue.line),
              guidance: issue.guidance
            )
          end
        end
      end

      def runtime_contract_issues(node, line_offset: 0)
        visitor = RuntimeContractVisitor.new
        visitor.visit(node)
        visitor.issues.map { _1.with(line: _1.line + line_offset) }
      end

      def erb_runtime_contract_issues(source)
        source.to_enum(:scan, ERB_TAG_PATTERN).flat_map do
          match = Regexp.last_match
          fragment = match[2].sub(/\bdo(?:\s*\|[^|]*\|)?\s*\z/, "")
          result = Prism.parse(fragment)
          next [] unless result.success?

          line_offset = source[0...match.begin(2)].count("\n")
          runtime_contract_issues(result.value, line_offset:)
        end
      end

      def runtime_ruby_source(path)
        case path.extname
        when ".rb" then path.read
        when ".erb" then erb_ruby_source(path.read)
        end
      end

      def erb_ruby_source(source)
        ruby = source.gsub(/[^\n]/, " ")
        source.to_enum(:scan, ERB_TAG_PATTERN).each do
          match = Regexp.last_match
          next if match[1]&.include?("=") && !standalone_erb_tag?(source, match)

          ruby[match.begin(2)...match.end(2)] = match[2]
        end
        ruby
      end

      def standalone_erb_tag?(source, match)
        line_break = source.rindex("\n", match.begin(0) - 1)
        line_start = line_break ? line_break + 1 : 0
        line_end = source.index("\n", match.end(0)) || source.length

        source[line_start...match.begin(0)].strip.empty? && source[match.end(0)...line_end].strip.empty?
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
        @all_findings ||= (legacy_helpers + copied_components + controllers + vendored_dependencies + application_button_treatments + runtime_contract_errors)
          .uniq { [ _1.status, _1.path, _1.guidance ] }
      end

      def source_files
        application_root.glob("app/**/*.{rb,erb,haml,slim}").select(&:file?)
      end

      def application_stylesheets
        application_root.glob("app/**/*.{css,scss,sass}").select(&:file?)
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
