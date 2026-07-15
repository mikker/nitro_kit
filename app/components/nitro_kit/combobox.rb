# frozen_string_literal: true

module NitroKit
  class Combobox < Component
    PLACEMENTS = %i[bottom_start bottom_end top_start top_end].freeze

    Option = NitroKit::Choice

    def initialize(
      id:,
      name:,
      label:,
      options:,
      value: nil,
      placeholder: nil,
      placement: :bottom_start,
      required: false,
      disabled: false,
      autocomplete: "off",
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @name = form_name(name)
      @label = accessible_label(label)
      @options = typed_options(options)
      @value = value
      @selected_option = selected_option(value)
      @placeholder = placeholder
      @placement = validate_choice!(:placement, placement, PLACEMENTS)
      @required = validate_boolean!(:required, required)
      @disabled = validate_boolean!(:disabled, disabled)
      @autocomplete = autocomplete

      if !value.nil? && !@selected_option
        raise ArgumentError, "Combobox value #{value.inspect} does not match a declared option"
      end

      super(
        component: :combobox,
        attributes: {
          id: @identifier,
          role: "group",
          aria: { label: @label },
          data: {
            controller: "nk--combobox",
            placement: placement_value,
            state: "closed",
            action: "click@window->nk--combobox#closeFromOutside",
            nk__combobox_open_value: "false",
            nk__combobox_required_value: @required
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
        render_control
        render_native_select
        render_listbox
        render_status
      end
    end

    private

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
            aria: {
              label:,
              autocomplete: "list",
              controls: listbox_id,
              expanded: false,
              required: @required
            },
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
          include_blank: @placeholder || true,
          disabled: @disabled,
          required: @required,
          autocomplete: @autocomplete,
          data: { nk__combobox_target: "native" },
          control_aria: { label: },
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
            aria: { label: },
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
              selected:
            },
            data: {
              value: option.value.to_s,
              state: selected ? "selected" : "unselected",
              nk__combobox_target: "option",
              action: option.disabled ? nil : "click->nk--combobox#select pointermove->nk--combobox#activate"
            }
          }
        )
      ) { plain(option.label.to_s) }
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
        unless option.is_a?(Option) || option.is_a?(Hash) || option.is_a?(Array)
          raise ArgumentError, "Combobox options must be Choice instances, Hashes, or label/value Arrays"
        end

        Option.coerce(option)
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

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "Combobox id must be a non-blank String without whitespace"
    end

    def form_name(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox name must be a non-blank String"
    end

    def accessible_label(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Combobox label must be a non-blank String"
    end
  end
end
