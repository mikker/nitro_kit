# frozen_string_literal: true

module NitroKit
  class Accordion < Component
    def initialize(**attrs)
      super(
        attrs,
        class: item_class,
        data: {controller: "nk--accordion"}
      )
    end

    def view_template
      div(**attrs) do
        yield
      end
    end

    builder_method def item(**attrs)
      div(**attrs) do
        yield
      end
    end

    builder_method def trigger(text = nil, **attrs)
      button(
        **mattr(
          attrs,
          type: "button",
          class: trigger_class,
          data: {
            action: "nk--accordion#toggle",
            nk__accordion_target: "trigger"
          },
          aria: {expanded: "false"}
        )
      ) do
        block_given? ? yield : plain(text)
        chevron_icon
      end
    end

    builder_method def content(**attrs)
      div(
        **mattr(
          attrs,
          class: content_class,
          data: {
            nk__accordion_target: "content"
          },
          aria: {hidden: "true"}
        )
      ) do
        div(class: "pb-4") { yield }
      end
    end

    private

    def item_class
      "divide-y"
    end

    def trigger_class
      [
        "flex w-full items-center justify-between py-4 font-medium cursor-pointer",
        "group/accordion-trigger hover:underline transition-colors",
        "[&[aria-expanded='true']>svg]:rotate-180",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
      ]
    end

    def content_class
      [
        "overflow-hidden transition-all duration-200",
        "[&[aria-hidden='true']]:h-0 [&[aria-hidden='false']]:h-auto"
      ]
    end

    def arrow_class
      "transition-transform duration-200 text-muted-content group-hover/accordion-trigger:text-primary"
    end

    def chevron_icon
      svg(
        class: "transition-transform duration-200 size-4 self-center place-self-end mr-2 pointer-events-none text-muted-content group-hover/accordion-trigger:text-primary",
        viewbox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: 1
      ) do |svg|
        svg.path(d: "m6 9 6 6 6-6")
      end
    end
  end
end
