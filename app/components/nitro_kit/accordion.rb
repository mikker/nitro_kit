# frozen_string_literal: true

module NitroKit
  class Accordion < Component
    def view_template
      div(
        **attrs,
        class: merge(item_class, attrs[:class]),
        data: {controller: "nk--accordion"}
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
        **attrs,
        class: merge(trigger_class, attrs[:class]),
        data: data_merge(attrs[:data], action: "nk--accordion#toggle", nk__accordion_target: "trigger"),
        aria: {expanded: "false"}
      ) do
        block_given? ? yield : plain(text)
        render(NitroKit::Icon.new(name: "chevron-down", class: arrow_class))
      end
    end

    def content(**attrs)
      div(
        **attrs,
        class: merge(content_class, attrs[:class]),
        data: data_merge(attrs[:data], nk__accordion_target: "content"),
        aria: {hidden: "true"}
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
      "transition-transform duration-200 text-muted-foreground group-hover/accordion-trigger:text-primary"
    end
  end
end
