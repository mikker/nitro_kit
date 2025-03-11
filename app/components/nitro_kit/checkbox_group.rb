# frozen_string_literal: true

module NitroKit
  class CheckboxGroup < Component
    def initialize(options = nil, **attrs)
      @options = options

      super(
        attrs,
        class: "flex items-start flex-col gap-2"
      )
    end

    attr_reader :options

    def view_template
      div(**attrs) do
        if block_given?
          yield
        else
          options.map { |option| item(*option) }
        end
      end
    end

    builder_method def title(text = nil, **attrs, &block)
      render(Label.new(**attrs)) do
        text_or_block(text, &block)
      end
    end

    builder_method def item(text = nil, **attrs, &block)
      render(Checkbox.new(**attrs)) do
        text_or_block(text, &block)
      end
    end
  end
end
