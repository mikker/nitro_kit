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
      required: false,
      size: :md,
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
      @required = validate_boolean!(:required, required)
      @size = validate_choice!(:size, size, Checkbox::SIZES)

      raise ArgumentError, "options cannot be empty" if @options.empty?
      validate_unique_choices!
      if include_hidden && unchecked_value.nil?
        raise ArgumentError, "unchecked_value cannot be nil when include_hidden is true"
      end

      super(
        component: :checkbox_group,
        size: @size,
        attributes: {
          id: @id,
          disabled: @disabled,
          aria: { required: @required ? "true" : nil }.compact,
          data: { orientation: @orientation, presentation: @presentation }
        }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :legend, :options, :name, :value, :description, :id, :size, :orientation, :presentation

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

    # The fieldset and its legend already scope the group description, so a
    # choice never repeats it through aria-describedby.
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
          size:
        ),
        :choice
      )
    end

    def multiple_name(name)
      name.end_with?("[]") ? name : "#{name}[]"
    end

    def deterministic_id(name)
      derived = name.to_s.gsub(/[^a-zA-Z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "")
      return derived unless derived.empty?

      raise ArgumentError, "name #{name.inspect} cannot derive an id; pass id:"
    end

    def choice_id(index)
      "#{id}-#{index}" if id
    end

    def validate_text!(name, text)
      return text if text.is_a?(String) && !text.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_unique_choices!
      duplicate_value = options.group_by { |choice| choice.value.to_s }.find { |_value, matches| matches.many? }
      raise ArgumentError, "choice values must be unique" if duplicate_value

      ids = options.each_with_index.filter_map { |choice, index| choice.id || choice_id(index) }
      raise ArgumentError, "choice ids must be unique" unless ids.uniq.length == ids.length
    end
  end
end
