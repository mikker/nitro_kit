module IgnitionKit
  class Accordion < Component
    ITEM = "divide-y"

    TRIGGER = [
      "flex w-full items-center justify-between py-4 font-medium cursor-pointer",
      "group/accordion-trigger hover:underline transition-colors",
      "[&[aria-expanded='true']>svg]:rotate-180",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
    ].freeze

    CONTENT = [
      "overflow-hidden transition-all duration-200",
      "[&[aria-hidden='true']]:h-0 [&[aria-hidden='false']]:h-auto"
    ].freeze

    ARROW =  "transition-transform duration-200 text-muted-foreground group-hover/accordion-trigger:text-primary"

    def view_template
      div(
        **attrs,
        class: merge([ITEM, class_list]),
        data: { controller: "ik--accordion" }
      ) do
        yield
      end
    end

    def item(**attrs)
      div(**attrs) do
        yield
      end
    end

    def trigger(text = nil, **attrs)
      button(
        type: "button",
        class: TRIGGER,
        data: {
          action: "ik--accordion#toggle",
          "ik--accordion-target": "trigger"
        },
        aria: { expanded: "false", controls: "content" }
      ) do
        div(**attrs) { text || yield }
        render IgnitionKit::Icon.new(name: "chevron-down", class: ARROW)
      end
    end

    def content(**attrs)
      div(
        class: merge(CONTENT),
        data: { "ik--accordion-target": "content" },
        aria: { hidden: "true" }
      ) do
        div(class: "pb-4") { yield }
      end
    end
  end
end 