module IgnitionKit
  class Accordion < Component
    TRIGGER = [
      "flex w-full items-center justify-between py-4 px-6 font-medium",
      "hover:bg-muted/50 transition-colors",
      "[&[aria-expanded='true']>svg]:rotate-180",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
    ].freeze

    CONTENT = [
      "overflow-hidden transition-all duration-200",
      "[&[aria-hidden='true']]:h-0 [&[aria-hidden='false']]:h-auto"
    ].freeze

    def view_template(&block)
      div(
        class: merge(["rounded-lg border divide-y", attrs[:class]]),
        data: { controller: "ik--accordion" }
      ) do
        yield(self)
      end
    end

    def item(title, **attrs, &block)
      div(**attrs) do
        button(
          type: "button",
          class: merge(TRIGGER),
          data: {
            action: "ik--accordion#toggle",
            "ik--accordion-target": "trigger"
          },
          aria: { expanded: "false", controls: "content" }
        ) do
          span { title }
          render IgnitionKit::Icon.new(name: "chevron-down", class: "transition-transform duration-200")
        end

        div(
          class: merge(CONTENT),
          data: { "ik--accordion-target": "content" },
          aria: { hidden: "true" }
        ) do
          div(class: "px-6 pb-4") { safe(capture(&block)) }
        end
      end
    end
  end
end 