# frozen_string_literal: true

module NitroKit
  class Tooltip < Component
    def initialize(content: nil, placement: nil, **attrs)
      @string_content = content
      @placement = placement

      super(
        attrs,
        data: {
          action: "mouseover->nk--tooltip#open mouseout->nk--tooltip#close",
          controller: "nk--tooltip",
          nk__tooltip_placement_value: placement
        }
      )
    end

    attr_reader :placement, :string_content

    def view_template
      span(**attrs) do
        content(string_content) if string_content
        yield
      end
    end

    builder_method def content(text = nil, **attrs, &block)
      div(
        **mattr(
          attrs,
          class: tooltip_class,
          data: {
            state: "closed",
            nk__tooltip_target: "content"
          }
        )
      ) do
        text_or_block(text, &block)
      end
    end

    private

    def tooltip_class
      [
        "absolute z-50 overflow-hidden w-fit max-w-sm",
        "px-3 py-1.5 text-sm bg-background rounded-md border shadow-sm",
        "data-[state=closed]:hidden"
      ]
    end
  end
end
