# frozen_string_literal: true

module NitroKit
  class RadioButton < Component
    SIZES = %i[md lg].freeze

    def initialize(
      label: nil,
      description: nil,
      id: nil,
      name: nil,
      value: "1",
      checked: false,
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
      @checked = validate_boolean!(:checked, checked)
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)
      @invalid = validate_boolean!(:invalid, invalid)
      @size = validate_choice!(:size, size, SIZES)
      @control_html = control_html
      @control_aria = control_aria
      @control_data = control_data

      if description && (!id.is_a?(String) || id.strip.empty?)
        raise ArgumentError, "radio button requires a non-blank String id when description is present"
      end

      super(
        component: :radio_button,
        size: @size,
        attributes: {
          data: { disabled: @disabled ? "true" : nil }.compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :label, :description, :id, :name, :value, :size

    def view_template(&block)
      require_accessible_name!(&block)

      div(**root_attributes) do
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

    def render_control
      render_in_slot(
        Input.new(
          type: :radio,
          id:,
          name:,
          value:,
          checked: @checked,
          disabled: @disabled,
          required: @required,
          html: @control_html,
          aria: control_aria,
          data: @control_data
        ),
        :control
      )
    end
  end
end
