module NitroKit
  class Field < Component
    FIELD = [
      "flex flex-col gap-2 align-start",
      "[&:has([data-slot='error'])_[data-slot='control']]:border-destructive"
    ].freeze

    DESCRIPTION = "text-sm text-muted-foreground"
    ERROR = "text-sm text-destructive"

    def initialize(
      name,
      as: :string,
      label: nil,
      description: nil,
      errors: nil,
      **attrs
    )
      super(**attrs)

      @name = name
      @as = as.to_sym

      # select
      @options = attrs[:options]

      @field_attrs = attrs
      @field_label = label || name.to_s.humanize
      @field_description = description
      @field_error_messages = errors
    end

    attr_reader(
      :name,
      :as,
      :field_attrs,
      :field_label,
      :field_description,
      :field_error_messages
    )

    def view_template
      div(**attrs, class: merge(FIELD, attrs[:class])) do
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
      end
    end

    private

    def default_field
      label
      description
      control
      errors
    end

    alias :html_input :input

    def input(**attrs)
      render(
        Input.new(
          name:,
          **field_attrs,
          **attrs,
          data: {slot: "control", **data_merge(field_attrs[:data], attrs[:data])}
        )
      )
    end

    alias :html_select :select

    def select(options: [], **attrs)
      render(
        Select.new(
          @options,
          name:,
          **field_attrs,
          **attrs,
          data: {slot: "control", **data_merge(field_attrs[:data], attrs[:data])}
        )
      )
    end
  end
end
