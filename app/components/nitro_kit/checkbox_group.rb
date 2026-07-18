# frozen_string_literal: true

module NitroKit
  class CheckboxGroup < Component
    ORIENTATIONS = %i[vertical horizontal].freeze
    PRESENTATIONS = %i[list cards].freeze

    alias :html_legend :legend

    def initialize(
      legend:,
      options:,
      name:,
      value: [],
      id: nil,
      description: nil,
      orientation: :vertical,
      presentation: :list,
      unchecked_value: "",
      include_hidden: true,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @legend = validate_text!(:legend, legend)
      @options = Array(options).map { |choice| Choice.coerce(choice) }.freeze
      @name = multiple_name(validate_text!(:name, name))
      @value = Array(value).map(&:to_s).freeze
      @id = id || deterministic_id(name)
      @description = validate_optional_text!(:description, description)
      @orientation = validate_choice!(:orientation, orientation, ORIENTATIONS)
      @presentation = validate_choice!(:presentation, presentation, PRESENTATIONS)
      @unchecked_value = unchecked_value
      @include_hidden = validate_boolean!(:include_hidden, include_hidden)
      @disabled = validate_boolean!(:disabled, disabled)

      raise ArgumentError, "options cannot be empty" if @options.empty?
      validate_unique_choices!
      if include_hidden && unchecked_value.nil?
        raise ArgumentError, "unchecked_value cannot be nil when include_hidden is true"
      end

      super(
        component: :checkbox_group,
        attributes: {
          id: @id,
          disabled: @disabled,
          data: { orientation: @orientation, presentation: @presentation }
        }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :legend, :options, :name, :value, :description, :id, :orientation, :presentation

    def view_template
      fieldset(**root_attributes) do
        html_legend(**slot_attributes(:legend)) { plain(legend) }
        if description
          p(**slot_attributes(:description, attributes: { id: description_id }.compact)) do
            plain(description.to_s)
          end
        end

        render_hidden_control
        div(**slot_attributes(:choices)) do
          options.each_with_index { |choice, index| render_choice(choice, index) }
        end
      end
    end

    private

    def render_hidden_control
      return unless @include_hidden

      render_in_slot(
        Input.new(
          type: :hidden,
          name:,
          value: @unchecked_value,
          disabled: @disabled,
          autocomplete: "off"
        ),
        :unchecked
      )
    end

    def render_choice(choice, index)
      render_in_slot(
        Checkbox.new(
          label: choice.label,
          description: choice.description,
          id: choice.id || choice_id(index),
          name:,
          value: choice.value,
          include_hidden: false,
          checked: value.include?(choice.value.to_s),
          disabled: @disabled || choice.disabled,
          control_aria: { describedby: description_id }.compact
        ),
        :choice
      )
    end

    def multiple_name(name)
      name.end_with?("[]") ? name : "#{name}[]"
    end

    def deterministic_id(name)
      name.to_s.gsub(/[^a-zA-Z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "").presence
    end

    def choice_id(index)
      "#{id}-#{index}" if id
    end

    def description_id
      "#{id}-description" if id && description
    end

    def validate_text!(name, text)
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, text)
      return if text.nil?
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String or nil"
    end

    def validate_unique_choices!
      duplicate_value = options.group_by { |choice| choice.value.to_s }.find { |_value, matches| matches.many? }
      raise ArgumentError, "choice values must be unique" if duplicate_value

      ids = options.each_with_index.filter_map { |choice, index| choice.id || choice_id(index) }
      raise ArgumentError, "choice ids must be unique" unless ids.uniq.length == ids.length
    end
  end
end
