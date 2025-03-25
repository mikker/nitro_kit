# frozen_string_literal: true

module NitroKit
  class Card < Component
    def initialize(**attrs)
      super(
        attrs,
        class: base_class
      )
    end

    def view_template
      div(**attrs) do
        yield
      end
    end

    builder_method def title(text = nil, **attrs, &block)
      h2(**mattr(attrs, class: "text-lg font-bold -mb-2")) do
        text_or_block(text, &block)
      end
    end

    builder_method def body(text = nil, **attrs, &block)
      div(**mattr(attrs, class: "text-muted-content text-sm leading-relaxed")) do
        text_or_block(text, &block)
      end
    end

    builder_method def footer(text = nil, **attrs, &block)
      div(**mattr(attrs, class: "flex gap-2 items-center")) do
        text_or_block(text, &block)
      end
    end

    builder_method def divider(**attrs)
      full_width do
        hr(**attrs)
      end
    end

    builder_method def full_width(**attrs)
      div(**mattr(attrs, data: {slot: "full"}, class: "-mx-(--gap)")) do
        yield
      end
    end

    private

    def base_class
      [
        # Configure spacing with breakpoints
        "[--gap:calc(var(--spacing)*4)] sm:[--gap:calc(var(--spacing)*6)]",
        # Base styles
        "flex flex-col items-stretch rounded-lg bg-background border p-(--gap) gap-(--gap) overflow-hidden",
        # If a `data-slot=full` is the first thing, move it to the top
        "[&>[data-slot=full]:first-child]:-mt-(--gap)",
        # Group for hover, focus
        "group/card"
      ]
    end
  end
end
