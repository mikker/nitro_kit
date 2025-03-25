# frozen_string_literal: true

module NitroKit
  class Field < Component
    def initialize(
      form = nil,
      field_name = nil,
      as: :string,
      label: nil,
      description: nil,
      errors: nil,
      wrapper: {},
      options: nil,
      **attrs
    )
      @form = form
      @field_name = field_name.to_s
      @as = as.to_sym

      @name = attrs[:name] || form&.field_name(field_name)
      @id = attrs[:id] || form&.field_id(field_name)

      # select, radio group
      @options = options

      @field_attrs = attrs
      @field_label = label.nil? ? field_name.to_s.humanize : label
      @field_description = description
      @field_error_messages = errors

      @wrapper = wrapper

      super(
        wrapper,
        data: {as: @as},
        class: base_class
      )
    end

    attr_reader(
      :as,
      :form,
      :name,
      :id,
      :field_attrs,
      :field_label,
      :field_description,
      :field_error_messages
    )

    def view_template
      div(**attrs) do
        if block_given?
          yield
        else
          default_field
        end
      end
    end

    alias :html_label :label

    builder_method def label(text = nil, **attrs)
      text ||= field_label

      return unless text

      render(Label.new(**mattr(attrs, for: id, data: {slot: "label"}))) do
        text
      end
    end

    builder_method def description(text = nil, **attrs, &block)
      text ||= field_description

      return unless text || block_given?

      div(**mattr(attrs, data: {slot: "description"}, class: description_class)) do
        text_or_block(text, &block)
      end
    end

    builder_method def errors(error_messages = nil, **attrs)
      error_messages ||= field_error_messages

      return unless error_messages&.any?

      ul(**mattr(attrs, data: {slot: "error"}, class: error_class)) do |msg|
        error_messages.each do |msg|
          li { msg }
        end
      end
    end

    builder_method def control(**attrs)
      case as
      when :string
        input(**attrs)
      when
          :button,
          :color,
          :date,
          :datetime,
          :datetime_local,
          :email,
          :file,
          :hidden,
          :month,
          :number,
          :password,
          :range,
          :search,
          :tel,
          :text,
          :time,
          :url,
          :week
        input(type: as, **attrs)
      when :select
        select(**attrs)
      when :textarea
        textarea(**attrs)
      when :checkbox
        checkbox(**attrs)
      when :combobox
        combobox(**attrs)
      when :radio, :radio_button, :radio_group
        radio_group(**attrs)
      when :switch
        switch(**attrs)
      else
        raise ArgumentError, "Invalid field type `#{as}'"
      end
    end

    private

    def default_field
      case as
      when :checkbox
        control
        label
        description
        errors
      else
        label
        description
        control
        errors
      end
    end

    def control_attrs(**attrs)
      mattr(
        attrs,
        name:,
        id:,
        value: value_before_typecast,
        data: {slot: "control"}
      )
    end

    alias :html_input :input

    def input(**attrs)
      render(
        Input.new(
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    alias :html_select :select

    def select(options: nil, **attrs)
      render(
        Select.new(
          options || @options || [],
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    alias :html_textarea :textarea

    def textarea(**attrs)
      render(
        Textarea.new(
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    def checkbox(**attrs)
      render(
        Checkbox.new(
          checked: checked?,
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    def combobox(**attrs)
      render(
        Combobox.new(
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    def radio_group(options: nil, **attrs)
      render(
        RadioButtonGroup.new(
          options || @options || [],
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    def switch(**attrs)
      # TODO: support use in forms
      render(
        Switch.new(
          **control_attrs(
            **field_attrs,
            **attrs
          )
        )
      )
    end

    private

    def base_class
      [
        "grid align-start",
        # Margins
        "[&>[data-slot=label]+[data-slot=control]]:mt-2 [&>[data-slot=label]+[data-slot=description]]:mt-1 [&>[data-slot=description]+[data-slot=control]]:mt-3 [&>[data-slot=control]+[data-slot=description]]:mt-3 [&>[data-slot=control]+[data-slot=error]]:mt-2",
        # When checkbox
        "[&[data-as=checkbox]]:grid-cols-[auto_1fr] data-[as=checkbox]:gap-x-2 [&[data-as=checkbox]_[data-slot=description]]:col-start-2",
        "[&:has([data-slot=error])_[data-slot=control]]:border-destructive"
      ]
    end

    def description_class
      "text-sm text-muted-content"
    end

    def error_class
      "text-sm text-destructive-content"
    end

    def value
      return attrs[:value] if attrs[:value]
      return unless object = form&.object

      if object.respond_to?(@field_name)
        object.public_send(@field_name)
      end
    end

    def value_before_typecast
      return attrs[:value] if attrs[:value]
      return unless object = form&.object

      method_before_type_cast = @field_name + "_before_type_cast"

      if object.respond_to?(method_before_type_cast)
        object.public_send(method_before_type_cast)
      else
        value
      end
    end

    def checked?
      return unless object = form&.object
      value = object.public_send(@field_name)

      case value
      when true, false
        value
      when String
        value == "1"
      when Numeric
        value == 1
      else
        false
      end
    end
  end
end
