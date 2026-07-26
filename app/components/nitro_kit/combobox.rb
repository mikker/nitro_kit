# frozen_string_literal: true

module NitroKit
  class Combobox < Component
    PLACEMENTS = %i[bottom_start bottom_end top_start top_end].freeze

    def initialize(
      id:,
      name:,
      label:,
      options:,
      value: nil,
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
      @identifier = component_id(id)
      @name = form_name(name)
      @label = visible_label(label)
      @options = typed_options(options)
      @value = value
      @selected_option = selected_option(value)
      @placeholder = validate_optional_text!(:placeholder, placeholder)
      @include_blank = validate_blank_option!(include_blank)
      @placement = validate_choice!(:placement, placement, PLACEMENTS)
      @required = validate_boolean!(:required, required)
      @disabled = validate_boolean!(:disabled, disabled)
      @autocomplete = autocomplete
      @control_aria = attribute_hash(control_aria, name: "control_aria")

      if !value.nil? && !@selected_option
        raise ArgumentError, "Combobox value #{value.inspect} does not match a declared option"
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
            action: "click@window->nk--combobox#closeFromOutside",
            nk__combobox_open_value: "false",
            nk__combobox_required_value: @required,
            nk__combobox_invalid_selection_value: I18n.t("nitro_kit.combobox.invalid_selection"),
            nk__combobox_no_results_value: I18n.t("nitro_kit.combobox.no_results"),
            nk__combobox_results_one_value: I18n.t("nitro_kit.combobox.results.one"),
            nk__combobox_results_other_value: I18n.t("nitro_kit.combobox.results.other")
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :name, :label, :options, :value, :placement

    def view_template
      div(**root_attributes) do
        render_label
        render_control
        render_native_select
        render_listbox
        render_status
      end
    end

    private

    def render_label
      return if label == false

      render_in_slot(Label.new(label, for: input_id, id: label_id), :label)
    end

    def render_control
      span(**slot_attributes(:control, attributes: { hidden: true }, data: { nk__combobox_target: "control" })) do
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
              required: @required
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

        svg(
          **slot_attributes(
            :icon,
            attributes: {
              viewbox: "0 0 16 16",
              width: 16,
              height: 16,
              fill: "none",
              stroke: "currentColor",
              stroke_width: 1.5,
              stroke_linecap: "round",
              stroke_linejoin: "round",
              focusable: "false",
              aria: { hidden: true }
            }
          )
        ) { |svg| svg.path(d: "m4 6 4 4 4-4") }
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

    def render_listbox
      ul(
        **slot_attributes(
          :listbox,
          attributes: {
            id: listbox_id,
            role: "listbox",
            hidden: true,
            aria: accessible_naming,
            data: {
              placement: placement_value,
              state: "closed",
              nk__combobox_target: "listbox"
            }
          }
        )
      ) do
        options.each_with_index { |option, index| render_option(option, index) }
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

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "Combobox id must be a non-blank String without whitespace"
    end

    def form_name(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox name must be a non-blank String"
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
