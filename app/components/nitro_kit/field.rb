# frozen_string_literal: true

module NitroKit
  class Field < Component
    UNSET = Object.new.freeze
    private_constant :UNSET
    INPUT_TYPES = %i[
      button color date datetime datetime_local email file hidden month number password range
      search string tel text time url week
    ].freeze
    TYPES = (INPUT_TYPES + %i[select textarea rich_text checkbox radio radio_button radio_group switch]).freeze

    def initialize(
      form = nil,
      field_name = nil,
      as: :string,
      label: nil,
      description: nil,
      errors: nil,
      options: nil,
      option_tags: nil,
      include_blank: nil,
      prompt: nil,
      id: nil,
      name: nil,
      value: UNSET,
      placeholder: nil,
      disabled: false,
      readonly: false,
      required: false,
      autocomplete: nil,
      checked: nil,
      indeterminate: false,
      multiple: false,
      accept: nil,
      min: nil,
      max: nil,
      step: nil,
      minlength: nil,
      maxlength: nil,
      rows: nil,
      cols: nil,
      wrap: nil,
      pattern: nil,
      inputmode: nil,
      checked_value: "1",
      unchecked_value: "0",
      include_hidden: true,
      html: {},
      aria: {},
      data: {},
      control_html: {},
      control_aria: {},
      control_data: {},
      rich_text_content: nil,
      desperately_need_a_class: nil
    )
      @form = form
      @field_name = field_name&.to_s
      @as = validate_choice!(:as, as.to_s.tr("-", "_").to_sym, TYPES)
      @multiple = validate_boolean!(:multiple, multiple)
      @id = id || form&.field_id(field_name) || default_field_id
      @name = name || form&.field_name(field_name, multiple: @multiple) || default_field_name
      @explicit_value = value
      @field_label = label.nil? ? derived_label : label
      @field_description = description
      @field_error_messages = Array(errors).compact
      @options = options
      @option_tags = option_tags
      @include_blank = include_blank
      @prompt = prompt
      @placeholder = placeholder
      @disabled = validate_boolean!(:disabled, disabled)
      @readonly = validate_boolean!(:readonly, readonly)
      @required = validate_boolean!(:required, required)
      @autocomplete = autocomplete
      @checked = validate_boolean!(:checked, checked, allow_nil: true)
      @indeterminate = validate_boolean!(:indeterminate, indeterminate)
      @accept = accept
      @min = min
      @max = max
      @step = step
      @minlength = minlength
      @maxlength = maxlength
      @rows = rows
      @cols = cols
      @wrap = wrap
      @pattern = pattern
      @inputmode = inputmode
      @checked_value = checked_value
      @unchecked_value = unchecked_value
      @include_hidden = validate_boolean!(:include_hidden, include_hidden)
      @control_html = control_html
      @control_aria = control_aria
      @control_data = control_data
      @rich_text_content = rich_text_content

      if @options.is_a?(ActiveSupport::SafeBuffer)
        raise ArgumentError, "pass captured option markup through option_tags:"
      end
      if @as != :textarea && !(@rows.nil? && @cols.nil? && @wrap.nil?)
        raise ArgumentError, "rows:, cols:, and wrap: require as: :textarea"
      end
      if @as == :radio_group && @field_label == false
        raise ArgumentError, "as: :radio_group requires a legend; pass label: with the group name"
      end

      super(
        component: :field,
        attributes: {
          data: {
            field_type: @as.to_s.tr("_", "-"),
            state: @field_error_messages.any? ? "invalid" : nil,
            required: @required ? "true" : nil,
            disabled: @disabled ? "true" : nil
          }.compact
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :as, :form, :name, :id, :field_label, :field_description, :field_error_messages

    def view_template(&block)
      div(**root_attributes) do
        block ? yield : default_field
      end
    end

    def label(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      text = field_label if text.nil?
      return if text == false
      return unless !text.nil? || block

      render_in_slot(
        Label.new(
          text,
          for: id,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        ),
        :label,
        &block
      )
    end

    def description(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      text = field_description if text.nil?
      return unless !text.nil? || block

      div(
        **slot_attributes(
          :description,
          attributes: { id: description_id }.compact,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    def errors(error_messages = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      messages = error_messages.nil? ? field_error_messages : Array(error_messages).compact
      return if messages.empty?

      ul(
        **slot_attributes(
          :error,
          attributes: { id: errors_id, role: "alert" }.compact,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) do
        messages.each { |message| li { plain(message.to_s) } }
      end
    end

    def control(html: {}, aria: {}, data: {})
      case as
      when *INPUT_TYPES
        input_control(html:, aria:, data:)
      when :select
        select_control(html:, aria:, data:)
      when :textarea
        textarea_control(html:, aria:, data:)
      when :rich_text
        rich_text_control(html:, aria:, data:)
      when :checkbox
        checkbox_control(html:, aria:, data:)
      when :switch
        switch_control(html:, aria:, data:)
      when :radio, :radio_button
        radio_button_control(html:, aria:, data:)
      when :radio_group
        radio_group_control(html:, aria:, data:)
      end
    end

    private

    def default_field
      case as
      when :checkbox, :switch
        control
        description
      when :radio_group
        control
      else
        label
        description
        control
      end
      errors
    end

    def input_control(html:, aria:, data:)
      type = resolved_input_type
      render_in_slot(
        Input.new(
          type:,
          id:,
          name:,
          value: type == :file ? nil : normalized_value(type),
          placeholder: @placeholder,
          disabled: @disabled,
          readonly: @readonly,
          required: @required,
          autocomplete: @autocomplete,
          multiple: @multiple,
          accept: @accept,
          min: @min,
          max: @max,
          step: @step,
          minlength: @minlength,
          maxlength: @maxlength,
          pattern: @pattern,
          inputmode: @inputmode,
          html: @control_html.merge(html),
          aria: control_aria(aria),
          data: @control_data.merge(data)
        ),
        :control
      )
    end

    def select_control(html:, aria:, data:)
      render_in_slot(
        Select.new(
          options: @options || [],
          option_tags: @option_tags,
          id:,
          name:,
          value: current_value,
          include_blank: @include_blank,
          prompt: @prompt,
          disabled: @disabled,
          required: @required,
          multiple: @multiple,
          autocomplete: @autocomplete,
          control_html: @control_html.merge(html),
          control_aria: control_aria(aria),
          control_data: @control_data.merge(data)
        ),
        :control
      )
    end

    def textarea_control(html:, aria:, data:)
      render_in_slot(
        Textarea.new(
          id:,
          name:,
          value: current_value,
          placeholder: @placeholder,
          disabled: @disabled,
          readonly: @readonly,
          required: @required,
          autocomplete: @autocomplete,
          rows: @rows,
          cols: @cols,
          minlength: @minlength,
          maxlength: @maxlength,
          wrap: @wrap,
          html: @control_html.merge(html),
          aria: control_aria(aria),
          data: @control_data.merge(data)
        ),
        :control
      )
    end

    def rich_text_control(html:, aria:, data:)
      render_in_slot(
        RichTextArea.new(
          @rich_text_content,
          html: @control_html.merge(html),
          aria: control_aria(aria),
          data: @control_data.merge(data)
        ),
        :control
      )
    end

    def checkbox_control(html:, aria:, data:)
      render_in_slot(
        Checkbox.new(
          label: field_label == false ? nil : field_label,
          id:,
          name:,
          value: @checked_value,
          unchecked_value: @unchecked_value,
          include_hidden: @include_hidden,
          checked: checked?,
          indeterminate: @indeterminate,
          disabled: @disabled,
          required: @required,
          control_html: @control_html.merge(html),
          control_aria: control_aria(aria),
          control_data: @control_data.merge(data)
        ),
        :control
      )
    end

    def switch_control(html:, aria:, data:)
      render_in_slot(
        Switch.new(
          label: field_label == false ? nil : field_label,
          description: nil,
          id:,
          name:,
          value: @checked_value,
          unchecked_value: @unchecked_value,
          include_hidden: @include_hidden,
          checked: checked?,
          disabled: @disabled,
          required: @required,
          control_html: @control_html.merge(html),
          control_aria: switch_aria(aria),
          control_data: @control_data.merge(data)
        ),
        :control
      )
    end

    def radio_button_control(html:, aria:, data:)
      choice = normalized_options.first || Choice.new(label: @checked_value, value: @checked_value)

      render_in_slot(
        RadioButton.new(
          label: field_label == false ? nil : field_label,
          id:,
          name:,
          value: choice.value,
          checked: @checked.nil? ? current_value.to_s == choice.value.to_s : @checked,
          disabled: @disabled || choice.disabled,
          required: @required,
          control_html: @control_html.merge(html),
          control_aria: control_aria(aria),
          control_data: @control_data.merge(data)
        ),
        :control
      )
    end

    def radio_group_control(html:, aria:, data:)
      render_in_slot(
        RadioButtonGroup.new(
          legend: field_label || derived_label || "Options",
          options: normalized_options,
          name:,
          value: current_value,
          id:,
          description: field_description,
          disabled: @disabled,
          required: @required,
          html: @control_html.merge(html),
          aria: control_aria(aria),
          data: @control_data.merge(data)
        ),
        :control
      )
    end

    def control_aria(extra)
      attributes = @control_aria.merge(extra)
      provided_description = extract_aria_attribute!(attributes, :describedby)
      provided_invalid = extract_aria_attribute!(attributes, :invalid)
      described_by = [
        provided_description,
        field_description ? description_id : nil,
        field_error_messages.any? ? errors_id : nil
      ].compact.join(" ")

      attributes.merge(
        describedby: described_by.presence,
        invalid: field_error_messages.any? ? true : provided_invalid
      ).compact
    end

    def switch_aria(extra)
      attributes = control_aria(extra)
      return attributes unless field_label == false
      return attributes if attributes.keys.any? { |key| %w[label labelledby].include?(key.to_s.delete("_-")) }

      accessible_name = derived_label || name.to_s.humanize.presence
      raise ArgumentError, "an unlabeled switch requires a field name or control ARIA label" unless accessible_name

      attributes.merge(label: accessible_name)
    end

    def extract_aria_attribute!(attributes, name)
      key = attributes.keys.find { |candidate| candidate.to_s.delete("_-") == name.to_s.delete("_-") }
      attributes.delete(key) if key
    end

    def derived_label
      return unless @field_name

      object = form&.object
      if object && object.class.respond_to?(:human_attribute_name)
        object.class.human_attribute_name(@field_name)
      else
        @field_name.humanize
      end
    end

    def normalized_options
      @normalized_options ||= Array(@options).map { |choice| Choice.coerce(choice) }.freeze
    end

    def description_id
      "#{id}-description" if id
    end

    def default_field_id
      return unless @field_name

      @field_name.gsub(/[^a-zA-Z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "").presence
    end

    def default_field_name
      return unless @field_name

      @multiple ? "#{@field_name}[]" : @field_name
    end

    def errors_id
      "#{id}-errors" if id
    end

    def resolved_input_type
      case as
      when :string then :text
      when :datetime, :datetime_local then :"datetime-local"
      else as
      end
    end

    def normalized_value(type)
      value = current_value_before_type_cast
      return value unless type == :"datetime-local"
      return value if value.nil?

      if value.is_a?(String)
        stripped = value.strip
        return value if stripped.empty?
        return stripped if stripped.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?\z/)

        value = parse_datetime_value(stripped) || value
      end

      value.respond_to?(:strftime) ? value.strftime("%Y-%m-%dT%H:%M:%S") : value
    end

    def parse_datetime_value(value)
      Time.zone ? Time.zone.parse(value) : Time.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def current_value
      return @explicit_value unless @explicit_value.equal?(UNSET)
      return unless form&.object && @field_name && form.object.respond_to?(@field_name)

      form.object.public_send(@field_name)
    end

    def current_value_before_type_cast
      return @explicit_value unless @explicit_value.equal?(UNSET)
      return unless form&.object && @field_name

      before_type_cast = "#{@field_name}_before_type_cast"
      form.object.respond_to?(before_type_cast) ? form.object.public_send(before_type_cast) : current_value
    end

    def checked?
      return @checked unless @checked.nil?
      return true if current_value.to_s == @checked_value.to_s

      case current_value
      when true then true
      when String then current_value == "1"
      when Numeric then current_value == 1
      else false
      end
    end
  end
end
