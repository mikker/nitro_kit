# frozen_string_literal: true

module NitroKit
  class RadioButtonGroup < Component
    def initialize(options_arg = nil, options: [], name: nil, value: nil, **attrs)
      @options = options_arg || options

      @name = name
      @group_value = value

      super(
        attrs,
        name: @name,
        class: "flex items-start flex-col gap-2"
      )
    end

    attr_reader :name, :group_value, :options

    def view_template
      div(**attrs) do
        if block_given?
          yield
        else
          options.map { |o| item(*o) }
        end
      end
    end

    def title(text = nil, **attrs, &block)
      builder do
        render(Label.new(**attrs)) do
          text_or_block(text, &block)
        end
      end
    end

    def item(text = nil, value_as_arg = nil, value: nil, **attrs, &block)
      builder do
        value ||= value_as_arg

        render(
          RadioButton.new(
            **mattr(
              attrs,
              name: attrs.fetch(:name, name),
              value:,
              checked: group_value.presence == value
            )
          )
        ) do
          text_or_block(text, &block)
        end
      end
    end
  end
end
