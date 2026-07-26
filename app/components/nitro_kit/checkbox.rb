# frozen_string_literal: true

module NitroKit
  class Checkbox < Component
    SIZES = %i[md lg].freeze

    def initialize(
      label: nil,
      description: nil,
      id: nil,
      name: nil,
      value: "1",
      unchecked_value: "0",
      include_hidden: true,
      checked: false,
      indeterminate: false,
      disabled: false,
      required: false,
      invalid: false,
      size: :md,
      html: {},
      aria: {},
      data: {},
      control_html: {},
      control_aria: {},
      control_data: {},
      desperately_need_a_class: nil
    )
      @label = validate_optional_text!(:label, label)
      @description = validate_optional_text!(:description, description)
      @id = id
      @name = name
      @value = value
      @unchecked_value = unchecked_value
      @include_hidden = validate_boolean!(:include_hidden, include_hidden)
      @checked = validate_boolean!(:checked, checked)
      @indeterminate = validate_boolean!(:indeterminate, indeterminate)
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)
      @invalid = validate_boolean!(:invalid, invalid)
      @size = validate_choice!(:size, size, SIZES)
      @control_html = control_html
      @control_aria = control_aria
      @control_data = control_data

      if include_hidden && unchecked_value.nil?
        raise ArgumentError, "unchecked_value cannot be nil when include_hidden is true"
      end
      if description && (!id.is_a?(String) || id.strip.empty?)
        raise ArgumentError, "checkbox requires a non-blank String id when description is present"
      end

      super(
        component: :checkbox,
        size: @size,
        attributes: {
          data: indeterminate_data.merge(disabled: @disabled ? "true" : nil).compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :label, :description, :id, :name, :value, :unchecked_value, :size

    def view_template(&block)
      require_accessible_name!(&block)

      div(**root_attributes) do
        render_hidden_control

        if label.nil? && !block
          render_control
          span(**slot_attributes(:indicator), aria: { hidden: "true" })
        else
          render_in_slot(Label.new(for: id), :label) do
            render_control
            span(**slot_attributes(:indicator), aria: { hidden: "true" })
            span(**slot_attributes(:content)) do
              span(**slot_attributes(:label_text)) { text_or_block(label, &block) }
              span(**slot_attributes(:description, attributes: { id: description_id })) { plain(description) } if description
            end
          end
        end
      end
    end

    private

    # The native DOM property is the only checkbox state HTML cannot express, so
    # it is also the only state the enhancer and the root attribute carry.
    def indeterminate_data
      return {} unless @indeterminate

      {
        controller: "nk--checkable",
        action: "change->nk--checkable#change",
        state: "indeterminate",
        nk__checkable_indeterminate_value: "true"
      }
    end

    def render_hidden_control
      return unless @include_hidden && name

      render_in_slot(
        Input.new(
          type: :hidden,
          name:,
          value: unchecked_value,
          disabled: @disabled,
          autocomplete: "off"
        ),
        :unchecked
      )
    end

    def render_control
      render_in_slot(
        Input.new(
          type: :checkbox,
          id:,
          name:,
          value:,
          checked: @checked,
          disabled: @disabled,
          required: @required,
          html: @control_html,
          aria: control_aria,
          data: control_data
        ),
        :control
      )
    end

    def control_data
      return @control_data unless @indeterminate

      @control_data.merge(nk__checkable_target: "control")
    end
  end
end
