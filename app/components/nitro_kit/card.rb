# frozen_string_literal: true

module NitroKit
  class Card < Component
    def initialize(**attrs)
      @attrs = attrs
    end

    def view_template(&block)
      div(**attrs, class: merge(base_class, attrs[:class]), &block)
    end

    def title(text = nil, **attrs)
      h2(**attrs, class: merge("text-lg font-bold -mb-2", attrs[:class])) do
        text || (block_given? ? yield : nil)
      end
    end

    def body(text = nil, **attrs)
      div(**attrs, class: merge("text-muted-foreground text-sm leading-relaxed", attrs[:class])) do
        text || (block_given? ? yield : nil)
      end
    end

    def footer(text = nil, **attrs)
      div(**attrs, class: merge("flex gap-2 items-center", attrs[:class])) do
        text || (block_given? ? yield : nil)
      end
    end

    def divider(**attrs)
      full_width do
        hr(**attrs)
      end
    end

    def full_width(&block)
      div(data: {slot: "full"}, class: "-mx-(--space)", &block)
    end

    private

    def base_class
      [
        # Configure spacing with breakpoints
        "[--space:calc(var(--spacing)*4)] sm:[--space:calc(var(--spacing)*6)]",
        # Base styles
        "flex flex-col items-stretch rounded-lg bg-background border p-(--space) gap-(--space) overflow-hidden",
        # If a `data-slot=full` is the first thing, move it to the top
        "[&>[data-slot=full]:first-child]:-mt-(--space)",
        # Group for hover, focus
        "group/card"
      ]
    end
  end
end
