# frozen_string_literal: true

module NitroKit
  class Tooltip < Component
    def initialize(content: nil, placement: nil, **attrs)
      super(**attrs)

      @content = content
      @placement = placement
    end

    attr_reader :placement

    def view_template
      span(
        **attrs,
        data: data_merge(
          attrs[:data],
          action: "mouseover->nk--tooltip#open mouseout->nk--tooltip#close",
          controller: "nk--tooltip",
          nk__tooltip_placement_value: placement
        )
      ) do
        if @content
          content(@content)
        end

        yield
      end
    end

    def content(text = nil, **attrs)
      div(
        **attrs,
        class: merge(tooltip_class, attrs[:class]),
        data: data_merge(
          attrs[:data],
          state: "closed",
          nk__tooltip_target: "content"
        )
      ) do
        text ? plain(text) : yield
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
