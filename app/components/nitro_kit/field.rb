# frozen_string_literal: true

module NitroKit
  class Field < Component
    include ActionView::Helpers::FormHelper

    FIELD = [
      "grid gap-2 align-start",
      "[&[data-as=checkbox]]:grid-cols-[auto_1fr] [&[data-as=checkbox]_[data-slot=description]]:col-start-2",
      "[&:has([data-slot=error])_[data-slot=control]]:border-destructive"
    ].freeze

    DESCRIPTION = "text-sm text-muted-foreground"
    ERROR = "text-sm text-destructive"

    def initialize(
      form = nil,
      field_name = nil,
      as: :string,
      label: nil,
      description: nil,
      errors: nil,
      **attrs
    )
      super(**attrs)

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
      div(**attrs, data: data_merge(attrs[:data], as:), class: merge(FIELD, attrs[:class])) do
        if !block_given?
          default_field
        else
          yield
        end
      end
    end

    alias :html_label :label

    def label(text = nil, **attrs)
      text ||= field_label

      return unless text

      render(
        Label.new(
          **attrs,
          for: id,
          data: data_merge({slot: "label"}, attrs[:data])
        )
      ) do
        text
      end
    end

    def description(text = nil, **attrs)
      text ||= field_description

      return unless text

      div(
        data: {slot: "description"},
        class: merge(DESCRIPTION, attrs[:class])
      ) { text }
    end

    def errors(error_messages = nil, **attrs)
      error_messages ||= field_error_messages

      return unless error_messages&.any?

      ul(
        **attrs,
        data: {slot: "error"},
        class: merge([ERROR, attrs[:class]])
      ) do |msg|
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
      when :radio, :radio_group
        radio_group(**attrs)
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
      {
        name:,
        id:,
        **attrs,
        data: {slot: "control", **data_merge(field_attrs[:data], attrs[:data])}
      }
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
  end
end
