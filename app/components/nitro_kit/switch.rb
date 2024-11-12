module NitroKit
  class Switch < Component
    BUTTON = [
      "inline-flex items-center shrink-0",
      "bg-background rounded-full border",
      "transition-colors duration-200 ease-in-out",
      "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ring-offset-background",

      # Checked
      "[&[aria-checked='true']]:bg-foreground [&[aria-checked='true']]:border-foreground",

      # Checked > Handle
      "[&[aria-checked='false']_[data-slot='handle']]:bg-primary",
      "[&[aria-checked='true']_[data-slot='handle']]:translate-x-[calc(theme(spacing.5)-1px)] [&[aria-checked='true']_[data-slot='handle']]:bg-background"
    ].freeze

    HANDLE = [
      "pointer-events-none inline-block rounded-full shadow-sm ring-0",
      "transition translate-x-[3px] duration-200 ease-in-out"
    ].freeze

    SIZE = {
      base: "h-6 w-10 [&_[data-slot=handle]]:size-4 [&[aria-checked='true']_[data-slot='handle']]:translate-x-[calc(theme(spacing.5)-1px)]",
      sm: "h-5 w-8 [&_[data-slot=handle]]:size-3 [&[aria-checked='true']_[data-slot='handle']]:translate-x-[calc(theme(spacing.4)-1px)]"
    }

    def initialize(
      name,
      checked: false,
      disabled: false,
      size: :base,
      description: nil,
      **attrs
    )
      super(**attrs)

      @name = name
      @checked = checked
      @disabled = disabled
      @size = size
      @description = description
    end

    attr_reader :name, :checked, :disabled, :description, :size

    def view_template
      button(
        **attrs,
        type: "button",
        class: merge([BUTTON, SIZE[size], attrs[:class]]),
        data: data_merge(attrs[:data], {controller: "nk--switch", action: "nk--switch#toggle"}),
        role: "switch",
        aria: {checked: checked.to_s}
      ) do
        span(class: "sr-only") { description }
        handle
      end
    end

    private

    def handle
      span(aria: {hidden: true}, class: HANDLE, data: {slot: "handle"})
    end
  end
end
