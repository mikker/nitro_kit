# frozen_string_literal: true

module NitroKit
  class Select < Component
    def initialize(
      options: [],
      option_tags: nil,
      id: nil,
      name: nil,
      value: nil,
      include_blank: nil,
      prompt: nil,
      disabled: false,
      required: false,
      multiple: false,
      autocomplete: nil,
      html: {},
      aria: {},
      data: {},
      control_html: {},
      control_aria: {},
      control_data: {},
      desperately_need_a_class: nil
    )
      @options = Array(options).map { |choice| Choice.coerce(choice) }.freeze
      @option_tags = validate_option_tags!(option_tags)
      @value = value
      @include_blank = validate_blank_option!(include_blank)
      @prompt = validate_prompt!(prompt)
      if @include_blank && @prompt
        raise ArgumentError, "include_blank: and prompt: are mutually exclusive"
      end
      @disabled = validate_boolean!(:disabled, disabled)
      @required = validate_boolean!(:required, required)
      @multiple = validate_boolean!(:multiple, multiple)
      @name = multiple_name(name)
      @id = id
      @autocomplete = autocomplete
      @control_html = control_html
      @control_aria = control_aria
      @control_data = control_data

      if @option_tags && @options.any?
        raise ArgumentError, "options and option_tags are mutually exclusive"
      end

      super(
        component: :select,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :options, :value, :include_blank, :prompt, :name, :id

    def view_template
      span(**root_attributes) do
        select(**control_attributes) do
          render_blank_option if include_blank
          render_prompt_option if prompt && selected_values.empty?

          if @option_tags
            raw safe(@option_tags)
          else
            options.each { |choice| render_option(choice) }
          end
        end

        render_toggle_icon
      end
    end

    private

    def render_toggle_icon
      return if @multiple

      svg(
        **slot_attributes(
          :icon,
          attributes: {
            viewbox: "0 0 20 20",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 1.5,
            aria: { hidden: true }
          }
        )
      ) do |icon|
        icon.path(d: "m6.5 8 3.5 3.5L13.5 8", stroke_linecap: "round", stroke_linejoin: "round")
      end
    end

    def control_attributes
      slot_attributes(
        :control,
        attributes: {
          id:,
          name:,
          disabled: @disabled,
          required: @required,
          multiple: @multiple,
          autocomplete: @autocomplete
        }.compact,
        html: @control_html,
        aria: @control_aria,
        data: @control_data
      )
    end

    def render_blank_option
      text = include_blank == true ? "" : include_blank
      option(value: "", selected: selected_values.empty?) { plain(text.to_s) }
    end

    def render_prompt_option
      option(value: "", selected: true) { plain(prompt) }
    end

    def render_option(choice)
      option(
        id: choice.id,
        value: choice.value,
        selected: selected_values.include?(choice.value.to_s),
        disabled: choice.disabled
      ) { plain(choice.label.to_s) }
    end

    def selected_values
      @selected_values ||= Array(value).compact.map(&:to_s)
    end

    def multiple_name(name)
      return name unless @multiple && name && !name.end_with?("[]")

      "#{name}[]"
    end

    def validate_option_tags!(option_tags)
      return if option_tags.nil?
      return option_tags if option_tags.is_a?(ActiveSupport::SafeBuffer)

      raise ArgumentError, "option_tags must be an ActiveSupport::SafeBuffer"
    end

    def validate_blank_option!(value)
      return value if value.nil? || value == true || value == false || value.is_a?(String)

      raise ArgumentError, "include_blank must be true, false, nil, or a String"
    end

    def validate_prompt!(value)
      return if value.nil? || value == false
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "prompt must be a non-blank String, false, or nil"
    end
  end
end
