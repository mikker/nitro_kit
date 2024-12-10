# frozen_string_literal: true

module NitroKit
  class Switch < Component
    def initialize(
      checked: false,
      size: :md,
      description: nil,
      **attrs
    )
      @checked = checked
      @size = size
      @description = description

      super(**attrs)
    end

    attr_reader :checked, :description, :size

    def view_template
      button(
        **mattr(
          **attrs,
          type: "button",
          class: [base_class, size_class],
          data: {controller: "nk--switch", action: "nk--switch#toggle"},
          role: "switch",
          aria: {checked: checked.to_s}
        )
      ) do
        span(class: "sr-only") { description }
        handle
      end
    end

    private

    def handle
      span(aria: {hidden: true}, class: handle_class, data: {slot: "handle"})
    end

    def base_class
      [
        "inline-flex items-center shrink-0",
        "bg-background rounded-full border",
        "transition-colors duration-200 ease-in-out",
        "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ring-offset-background",

        # Checked
        "[&[aria-checked=true]]:bg-foreground [&[aria-checked=true]]:border-foreground",

        # Checked > Handle
        "[&[aria-checked=false]_[data-slot=handle]]:bg-primary",
        "[&[aria-checked=true]_[data-slot=handle]]:bg-background"
      ]
    end

    def handle_class
      [
        "pointer-events-none inline-block rounded-full shadow-sm ring-0",
        "transition translate-x-[3px] duration-200 ease-in-out"
      ]
    end

    def size_class
      case size
      when :md
        "h-6 w-10 [&_[data-slot=handle]]:size-4 [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.5)-1px)]"
      when :sm
        "h-5 w-8 [&_[data-slot=handle]]:size-3 [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.4)-1px)]"
      else
        raise ArgumentError, "Unknown size: #{size}"
      end
    end
  end
end
