# frozen_string_literal: true

module NitroKit
  class Checkbox < Component
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
        attributes: {
          data: {
            controller: "nk--checkable",
            action: "change->nk--checkable#change",
            state: @indeterminate ? "indeterminate" : (@checked ? "checked" : "unchecked"),
            disabled: @disabled ? "true" : nil,
            nk__checkable_indeterminate_value: @indeterminate.to_s
          }.compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :label, :description, :id, :name, :value, :unchecked_value

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
          aria: checkbox_aria,
          data: @control_data.merge(nk__checkable_target: "control")
        ),
        :control
      )
    end

    def checkbox_aria
      attributes = @control_aria.dup
      key = attributes.keys.find do |candidate|
        candidate.to_s.downcase.tr("_", "-").delete_prefix("aria-") == "describedby"
      end
      describedby = [ attributes.delete(key), description_id ].compact.join(" ").presence
      attributes = attributes.merge(describedby:)

      return attributes unless @indeterminate

      attributes.merge(checked: "mixed")
    end

    def description_id
      "#{id}-description" if description
    end

    def require_accessible_name!
      return if label || block_given? || accessible_name?

      raise ArgumentError, "checkbox requires a label, block, or accessible control name"
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
