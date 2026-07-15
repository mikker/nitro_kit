# frozen_string_literal: true

module NitroKit
  class RadioButton < Component
    SIZES = %i[md lg].freeze

    def initialize(
      label: nil,
      id: nil,
      name: nil,
      value: "1",
      checked: false,
      disabled: false,
      required: false,
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
      @id = id
      @name = name
      @value = value
      @checked = validate_boolean!(:checked, checked)
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)
      @size = validate_choice!(:size, size.to_s.to_sym, SIZES)
      @control_html = control_html
      @control_aria = control_aria
      @control_data = control_data

      super(
        component: :radio_button,
        size: @size,
        attributes: {
          data: {
            controller: "nk--checkable",
            action: "change->nk--checkable#change",
            state: @checked ? "checked" : "unchecked",
            disabled: @disabled ? "true" : nil
          }.compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :label, :id, :name, :value, :size

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
            span(**slot_attributes(:label_text)) { text_or_block(label, &block) }
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
          aria: @control_aria,
          data: @control_data.merge(nk__checkable_target: "control")
        ),
        :control
      )
    end

    def require_accessible_name!
      return if label || block_given? || accessible_name?

      raise ArgumentError, "radio button requires a label, block, or accessible control name"
    end

    def accessible_name?
      @control_aria.any? do |key, value|
        name = key.to_s.downcase.tr("_", "-").delete_prefix("aria-")
        %w[label labelledby].include?(name) && value.to_s.present?
      end
    end

    def validate_optional_text!(name, text)
      return if text.nil?
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String or nil"
    end
  end
end
