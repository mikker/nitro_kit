# frozen_string_literal: true

module NitroKit
  class Label < Component
    def initialize(text = nil, **attrs)
      @text = text

      super(
        attrs,
        class: "text-sm font-medium select-none",
        data: {slot: "label"}
      )
    end

    attr_reader :text

    def view_template(&block)
      label(**attrs) do
        text_or_block(text, &block)
      end
    end
  end
end
