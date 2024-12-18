# frozen_string_literal: true

module NitroKit
  class Field < Component
    include ActionView::Helpers::FormHelper

    def initialize(
      form = nil,
      field_name = nil,
      as: :string,
      label: nil,
      description: nil,
      errors: nil,
      **attrs
    )
      @form = form
      @field_name = field_name
      @as = as.to_sym

      @name = attrs[:name] || form&.field_name(field_name)
      @id = attrs[:id] || form&.field_id(field_name)

      # select
      @options = attrs[:options]

      @field_attrs = attrs
      @field_label = label || field_name.to_s.humanize
      @field_description = description
      @field_error_messages = errors

      super(
        attrs,
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

    def label(text = nil, **attrs)
      text ||= field_label

      return unless text

      render(Label.new(**mattr(attrs, for: id, data: {slot: "label"}))) do
        text
      end
    end

    def description(text = nil, **attrs, &block)
      text ||= field_description

      div(**mattr(attrs, data: {slot: "description"}, class: description_class)) do
        text_or_block(text, &block)
      end
    end

    def errors(error_messages = nil, **attrs)
      error_messages ||= field_error_messages

      return unless error_messages&.any?

      ul(**mattr(attrs, data: {slot: "error"}, class: error_class)) do |msg|
        error_messages.each do |msg|
          li { msg }
        end
      end
    end

    def control(**attrs)
      case as
      when :string
        input(**attrs)
      when :select
        select(**attrs)
      when :text, :textarea
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
        data: {slot: "control", **field_attrs.fetch(:data, {})}
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
        RadioGroup.new(
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
        "grid gap-2 align-start",
        "[&[data-as=checkbox]]:grid-cols-[auto_1fr] [&[data-as=checkbox]_[data-slot=description]]:col-start-2",
        "[&:has([data-slot=error])_[data-slot=control]]:border-destructive"
      ]
    end

    def description_class
      "text-sm text-muted-foreground"
    end

    def error_class
      "text-sm text-destructive"
    end
  end
end
