# frozen_string_literal: true

module NitroKit
  class RadioButtonGroup < Component
    ORIENTATIONS = %i[vertical horizontal].freeze
    PRESENTATIONS = %i[list cards segmented].freeze

    alias :html_legend :legend

    def initialize(
      legend:,
      options:,
      name:,
      value: nil,
      id: nil,
      description: nil,
      orientation: :vertical,
      presentation: :list,
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
      @name = validate_text!(:name, name)
      @value = value
      @id = id || deterministic_id(name)
      @description = validate_optional_text!(:description, description)
      @orientation = validate_choice!(:orientation, orientation, ORIENTATIONS)
      @presentation = validate_choice!(:presentation, presentation, PRESENTATIONS)
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)
      @size = validate_choice!(:size, size, RadioButton::SIZES)

      raise ArgumentError, "options cannot be empty" if @options.empty?
      validate_unique_choices!

      super(
        component: :radio_button_group,
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

        div(**slot_attributes(:choices)) do
          options.each_with_index { |choice, index| render_choice(choice, index) }
        end
      end
    end

    private

    # The fieldset and its legend already scope the group description, so a
    # choice never repeats it through aria-describedby.
    def render_choice(choice, index)
      render_in_slot(
        RadioButton.new(
          label: choice.label,
          description: choice.description,
          id: choice.id || choice_id(index),
          name:,
          value: choice.value,
          checked: selected?(choice),
          disabled: @disabled || choice.disabled,
          required: @required,
          size:
        ),
        :choice
      )
    end

    def selected?(choice)
      !value.nil? && value.to_s == choice.value.to_s
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
