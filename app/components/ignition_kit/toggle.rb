module IgnitionKit
  class Toggle < Component
    BASE = [
      "relative inline-flex items-center shrink-0 cursor-pointer rounded-full border transition-colors duration-200 ease-in-out",
      "bg-background",
      "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ring-offset-background",
      "[&[aria-checked='true']]:bg-muted [&[aria-checked='true']_span]:translate-x-[calc(theme(spacing.5)-1px)]"
    ].freeze

    HANDLE = [
      "pointer-events-none inline-block rounded-full bg-primary shadow ring-0",
      "transition translate-x-[3px] duration-200 ease-in-out"
    ].freeze

    SIZE = {
      base: "h-6 w-10 [&_[data-slot=handle]]:size-4 [&[aria-checked='true']_span]:translate-x-[calc(theme(spacing.5)-1px)]",
      sm: "h-5 w-8 [&_[data-slot=handle]]:size-3 [&[aria-checked='true']_span]:translate-x-[calc(theme(spacing.4)-1px)]"
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
      @description = description

      @class_list = merge(
        [
          BASE,
          SIZE[size],
          attrs.delete(:class)
        ]
      )
    end

    attr_reader :name, :checked, :disabled, :description

    def view_template
      button(
        **attrs,
        type: "button",
        class: class_list,
        data: {controller: "ik--toggle", action: "ik--toggle#toggle"},
        role: "switch",
        aria: {checked: checked.to_s}
      ) do
        span(class: "sr-only") { description }
        span(aria: {hidden: true}, class: HANDLE, data: {slot: "handle"})
      end
    end
  end
end
