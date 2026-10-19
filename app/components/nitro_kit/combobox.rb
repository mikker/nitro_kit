# frozen_string_literal: true

module NitroKit
  class Combobox < Component
    PLACEMENTS = %i[bottom_start bottom_end top_start top_end].freeze
    ACTION_METHODS = %i[post patch put].freeze

    # Server-rendered results for a remote Combobox. The application's search
    # endpoint renders this component (without a layout) for the `query`
    # parameter; the Combobox controller moves its items into the listbox.
    class Results < Component
      Item = ::Data.define(:kind, :label, :value, :description, :disabled, :url, :params, :method)
      private_constant :Item

      def initialize(
        id:,
        html: {},
        aria: {},
        data: {},
        desperately_need_a_class: nil
      )
        @identifier = validate_id!("Combobox::Results id:", id)
        @items = []

        super(
          component: :combobox_results,
          attributes: { id: "#{@identifier}-results" },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      end

      def option(label, value:, description: nil, disabled: false)
        ensure_collecting!
        choice = Choice.new(label:, value:, description:, disabled:)

        if @items.any? { |item| item.kind == :option && item.value.to_s == choice.value.to_s }
          raise ArgumentError, "Combobox::Results option values must be unique: #{choice.value}"
        end

        @items << Item.new(
          kind: :option,
          label: choice.label.to_s,
          value: choice.value,
          description: choice.description,
          disabled: choice.disabled,
          url: nil,
          params: nil,
          method: nil
        )
        nil
      end

      def action(label, url:, params: {}, method: :post, description: nil)
        ensure_collecting!
        unless params.is_a?(Hash)
          raise ArgumentError, "Combobox::Results action params: must be a Hash of form fields"
        end

        @items << Item.new(
          kind: :action,
          label: validate_text!("Combobox::Results action label", label),
          value: nil,
          description: validate_optional_text!("Combobox::Results action description", description),
          disabled: false,
          url: validate_text!("Combobox::Results action url:", url),
          params: params.to_h { |key, value| [ key.to_s, value.to_s ] },
          method: validate_choice!(:method, method, ACTION_METHODS)
        )
        nil
      end

      def view_template(&block)
        @collecting = true
        yield(self) if block
        @collecting = false

        ul(**root_attributes) do
          @items.each_with_index do |item, index|
            item.kind == :action ? render_action(item, index) : render_option(item, index)
          end
        end
      ensure
        @collecting = false
      end

      private

      def render_option(item, index)
        id = "#{@identifier}-result-#{index + 1}"

        li(
          **slot_attributes(
            :option,
            attributes: {
              id:,
              role: "option",
              aria: {
                disabled: item.disabled ? true : nil,
                selected: false,
                label: item.description ? item.label : nil,
                describedby: item.description ? "#{id}-description" : nil
              }.compact,
              data: {
                value: item.value.to_s,
                state: "unselected",
                nk__combobox_target: "option",
                action: item.disabled ? nil : "click->nk--combobox#select pointermove->nk--combobox#activate"
              }
            }
          )
        ) { render_item_content(item, id) }
      end

      def render_action(item, index)
        id = "#{@identifier}-action-#{index + 1}"

        li(
          **slot_attributes(
            :action,
            attributes: {
              id:,
              role: "option",
              aria: {
                selected: false,
                label: item.description ? item.label : nil,
                describedby: item.description ? "#{id}-description" : nil
              }.compact,
              data: {
                nk__combobox_target: "option",
                request_url: item.url,
                request_method: item.method.to_s,
                request_params: item.params.to_json,
                action: "click->nk--combobox#select pointermove->nk--combobox#activate"
              }
            }
          )
        ) do
          render_in_slot(Icon.new(:plus, size: :sm), :action_icon)
          render_item_content(item, id)
        end
      end

      def render_item_content(item, id)
        span(**slot_attributes(:option_label)) { plain(item.label) }
        return unless item.description

        span(**slot_attributes(:option_description, attributes: { id: "#{id}-description" })) do
          plain(item.description)
        end
      end

      def ensure_collecting!
        return if @collecting

        raise ArgumentError, "Combobox::Results items must be declared inside the render block"
      end

      def qualified_slot(slot)
        slot_name = normalize_identity(slot, name: "slot")
        slot_name.start_with?("combobox-") ? slot_name : "combobox-#{slot_name}"
      end
    end

    def initialize(
      id:,
      name:,
      label:,
      options: nil,
      value: nil,
      src: nil,
      selected: [],
      multiple: false,
      placeholder: nil,
      include_blank: true,
      placement: :bottom_start,
      required: false,
      disabled: false,
      autocomplete: "off",
      html: {},
      aria: {},
      data: {},
      control_aria: {},
      desperately_need_a_class: nil
    )
      @identifier = validate_id!("Combobox id", id)
      @src = validate_optional_text!(:src, src)
      @multiple = validate_boolean!(:multiple, multiple)
      @name = submitted_name(validate_text!("Combobox name", name))
      @label = visible_label(label)
      @placeholder = validate_optional_text!(:placeholder, placeholder)
      @include_blank = validate_blank_option!(include_blank)
      @placement = validate_choice!(:placement, placement, PLACEMENTS)
      @required = validate_boolean!(:required, required)
      @disabled = validate_boolean!(:disabled, disabled)
      @autocomplete = autocomplete
      @control_aria = attribute_hash(control_aria, name: "control_aria")

      if remote?
        validate_remote_options!(options:, value:, include_blank:)
        @options = [].freeze
        @selected = typed_selection(selected)
        @value = @selected.first&.value
        @selected_option = @multiple ? nil : @selected.first
      else
        validate_local_options!(selected:)
        @options = typed_options(options)
        @selected = [].freeze
        @value = value
        @selected_option = selected_option(value)

        if !value.nil? && !@selected_option
          raise ArgumentError,
            "Combobox value #{value.inspect} does not match a declared option; " \
            "pass value: nil or add the stale record to options:"
        end
      end

      if @label == false && !named_by_control_aria?
        raise ArgumentError,
          "a Combobox without label: requires control_aria: { label: } or control_aria: { labelledby: }"
      end

      super(
        component: :combobox,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--combobox",
            placement: placement_value,
            state: "closed",
            nk__combobox_open_value: "false",
            nk__combobox_required_value: @required,
            nk__combobox_invalid_selection_value: I18n.t("nitro_kit.combobox.invalid_selection"),
            nk__combobox_no_results_value: I18n.t("nitro_kit.combobox.no_results"),
            nk__combobox_results_one_value: I18n.t("nitro_kit.combobox.results.one"),
            nk__combobox_results_other_value: I18n.t("nitro_kit.combobox.results.other"),
            **remote_values
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :name, :label, :options, :value, :placement, :src, :selected

    def remote? = !@src.nil?

    def multiple? = @multiple

    def view_template
      div(**root_attributes) do
        render_label
        render_control
        if remote?
          render_remote_value
        else
          render_native_select
        end
        render_listbox
        render_selections if multiple?
        render_status
      end
    end

    private

    def render_label
      return if label == false

      render_in_slot(Label.new(label, for: input_id, id: label_id), :label)
    end

    def render_control
      span(
        **slot_attributes(
          :control,
          attributes: { hidden: remote? ? nil : true }.compact,
          data: { nk__combobox_target: "control" }
        )
      ) do
        render_in_slot(
          Input.new(
            type: :text,
            id: input_id,
            value: @selected_option&.label&.to_s,
            placeholder: @placeholder,
            disabled: @disabled,
            autocomplete: @autocomplete,
            html: { role: "combobox" },
            aria: @control_aria.merge(
              autocomplete: "list",
              controls: listbox_id,
              expanded: false,
              required: @required || nil
            ),
            data: {
              nk__combobox_target: "input",
              action: [
                "focus->nk--combobox#open",
                "input->nk--combobox#filter",
                "keydown->nk--combobox#navigate",
                "blur->nk--combobox#validate"
              ].join(" ")
            }
          ),
          :input
        )

        render_in_slot(Icon.new(remote? ? :search : :chevron_down, size: :sm), :icon)
      end
    end

    def render_native_select
      render_in_slot(
        Select.new(
          options:,
          id: value_id,
          name:,
          value: @selected_option&.value,
          include_blank: @include_blank,
          disabled: @disabled,
          required: @required,
          autocomplete: @autocomplete,
          data: { nk__combobox_target: "native" },
          control_aria: accessible_naming,
          control_data: { nk__combobox_target: "value" }
        ),
        :native
      )
    end

    # A remote combobox has no complete option list to fall back to, so its
    # submission source is one hidden field per selected value. Multiple mode
    # also submits Rails' blank `name[]` entry so clearing every chip clears
    # the association.
    def render_remote_value
      if multiple?
        input(
          **slot_attributes(
            :blank,
            attributes: { type: "hidden", name:, value: "", disabled: @disabled || nil, autocomplete: "off" }
          )
        )
      else
        input(
          **slot_attributes(
            :value,
            attributes: {
              type: "hidden",
              id: value_id,
              name:,
              value: @selected_option&.value.to_s,
              disabled: @disabled || nil,
              autocomplete: "off",
              data: { nk__combobox_target: "value" }
            }
          )
        )
      end
    end

    def render_listbox
      ul(
        **slot_attributes(
          :listbox,
          attributes: {
            id: listbox_id,
            role: "listbox",
            hidden: true,
            aria: accessible_naming.merge(multiselectable: multiple? ? "true" : nil).compact,
            data: {
              placement: placement_value,
              state: "closed",
              nk__combobox_target: "listbox"
            }
          }
        )
      ) do
        options.each_with_index { |option, index| render_option(option, index) }
        render_message if remote?
      end
    end

    def render_option(option, index)
      selected = option.equal?(@selected_option)

      li(
        **slot_attributes(
          :option,
          attributes: {
            id: option_id(index),
            role: "option",
            aria: {
              disabled: option.disabled ? true : nil,
              selected:,
              label: option.description ? option.label.to_s : nil,
              describedby: option.description ? option_description_id(index) : nil
            }.compact,
            data: {
              value: option.value.to_s,
              state: selected ? "selected" : "unselected",
              nk__combobox_target: "option",
              action: option.disabled ? nil : "click->nk--combobox#select pointermove->nk--combobox#activate"
            }
          }
        )
      ) do
        span(**slot_attributes(:option_label)) { plain(option.label.to_s) }

        if option.description
          span(
            **slot_attributes(:option_description, attributes: { id: option_description_id(index) })
          ) { plain(option.description) }
        end
      end
    end

    # Loading, error, and empty feedback for remote results. The controller
    # owns its text and `data-state`; it is presentational so it never joins
    # the option sequence.
    def render_message
      li(
        **slot_attributes(
          :message,
          attributes: {
            role: "presentation",
            hidden: true,
            data: { state: "idle", nk__combobox_target: "message" }
          }
        )
      )
    end

    def render_selections
      ul(
        **slot_attributes(
          :selections,
          attributes: {
            aria: accessible_naming,
            data: { nk__combobox_target: "selections" }
          }
        )
      ) do
        @selected.each { |choice| render_selection(choice) }
      end

      template(**slot_attributes(:selection_template, attributes: { data: { nk__combobox_target: "selectionTemplate" } })) do
        render_selection(nil)
      end
    end

    def render_selection(choice)
      label = choice&.label&.to_s

      li(
        **slot_attributes(
          :selection,
          attributes: {
            data: { value: choice&.value.to_s, nk__combobox_target: "selection" }
          }
        )
      ) do
        span(**slot_attributes(:selection_label)) { plain(label.to_s) }
        render_in_slot(
          Button.new(
            icon: :x,
            label: I18n.t("nitro_kit.combobox.remove", label: label || "%{label}"),
            variant: :ghost,
            size: :xs,
            disabled: @disabled,
            data: { action: "nk--combobox#remove" }
          ),
          :remove
        )
        input(
          **slot_attributes(
            :selection_value,
            attributes: {
              type: "hidden",
              name:,
              value: choice&.value.to_s,
              disabled: @disabled || nil,
              autocomplete: "off"
            }
          )
        )
      end
    end

    def render_status
      div(
        **slot_attributes(
          :status,
          attributes: {
            role: "status",
            aria: { live: "polite", atomic: "true" },
            data: { nk__combobox_target: "status" }
          }
        )
      )
    end

    def remote_values
      return {} unless remote?

      {
        nk__combobox_src_value: @src,
        nk__combobox_multiple_value: @multiple,
        nk__combobox_loading_value: I18n.t("nitro_kit.combobox.loading"),
        nk__combobox_error_value: I18n.t("nitro_kit.combobox.error"),
        nk__combobox_remove_value: I18n.t("nitro_kit.combobox.remove", label: "%{label}")
      }
    end

    def submitted_name(base)
      return base unless @multiple

      base.end_with?("[]") ? base : "#{base}[]"
    end

    def validate_remote_options!(options:, value:, include_blank:)
      raise ArgumentError, "Combobox src: and options: are mutually exclusive; the server renders remote results" if options
      raise ArgumentError, "Combobox src: selects through selected:, not value:" unless value.nil?
      raise ArgumentError, "Combobox include_blank: applies only to local options:" unless include_blank == true
    end

    def validate_local_options!(selected:)
      raise ArgumentError, "Combobox multiple: requires src:" if @multiple
      unless selected.is_a?(Array) && selected.empty?
        raise ArgumentError, "Combobox selected: requires src:; local options select through value:"
      end
    end

    def typed_selection(value)
      raise ArgumentError, "Combobox selected: must be an Array of choices" unless value.is_a?(Array)

      coerced = value.map do |choice|
        unless choice.is_a?(Choice) || choice.is_a?(Hash)
          raise ArgumentError, "Combobox selected: entries must be Choice instances or Hashes with label: and value:"
        end

        Choice.coerce(choice)
      end

      if !@multiple && coerced.size > 1
        raise ArgumentError, "Combobox selected: holds at most one choice unless multiple: true"
      end

      duplicates = coerced.group_by { |choice| choice.value.to_s }.select { |_key, choices| choices.many? }
      if duplicates.any?
        raise ArgumentError, "Combobox selected: values must be unique: #{duplicates.keys.join(", ")}"
      end

      coerced.freeze
    end

    def typed_options(value)
      unless value.is_a?(Array) && value.any?
        raise ArgumentError, "Combobox options must be a non-empty Array"
      end

      coerced = value.map do |option|
        unless option.is_a?(Choice) || option.is_a?(Hash) || option.is_a?(Array)
          raise ArgumentError, "Combobox options must be Choice instances, Hashes, or label/value Arrays"
        end

        Choice.coerce(option)
      end

      duplicates = coerced.group_by { |option| option.value.to_s }.select { |_key, options| options.many? }
      if duplicates.any?
        raise ArgumentError, "Combobox option values must be unique: #{duplicates.keys.join(", ")}"
      end

      coerced.freeze
    end

    def selected_option(value)
      return if value.nil?

      options.find { |option| option.value.to_s == value.to_s }
    end

    def placement_value
      placement.to_s.tr("_", "-")
    end

    def input_id
      "#{identifier}-input"
    end

    def value_id
      "#{identifier}-value"
    end

    def listbox_id
      "#{identifier}-listbox"
    end

    def option_id(index)
      "#{identifier}-option-#{index + 1}"
    end

    def option_description_id(index)
      "#{option_id(index)}-description"
    end

    def label_id
      "#{identifier}-label"
    end

    def accessible_naming
      return { labelledby: label_id } unless label == false

      naming = @control_aria.slice(*aria_naming_keys)
      naming.presence || {}
    end

    def named_by_control_aria?
      @control_aria.any? do |key, value|
        aria_naming_keys.include?(key) && value.to_s.present?
      end
    end

    def aria_naming_keys
      @control_aria.keys.select do |key|
        %w[label labelledby].include?(key.to_s.downcase.delete("_-"))
      end
    end

    def visible_label(value)
      return value if value == false
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox label must be a non-blank String or false"
    end

    def validate_optional_text!(name, value)
      return if value.nil?
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox #{name} must be a non-blank String or nil"
    end

    def validate_blank_option!(value)
      return value if value == true || value == false || value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox include_blank must be true, false, or a non-blank String"
    end
  end
end
