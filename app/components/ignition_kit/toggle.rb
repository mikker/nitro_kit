module IgnitionKit
  # These need JS to toggle the stats. Maybe we need to implement these as checkboxes to work with forms, not sure. Maybe include a hidden_field above to make sure we send an "off" value when unchecked similar to the checkbox helpers.
  class Toggle < Component
    BASE = [
      "relative inline-flex flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out",
      "h-[var(--toggle-height)] w-[calc(var(--handle-size)*2)]",
      "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
      "bg-zinc-200 [&[aria-checked='true']]:bg-primary",
      # Color
      "[--bg-color:var(--color-zinc-200)] [--bg-color-checked:var(--color-primary)]"
    ].freeze

    HANDLE = [
      "pointer-events-none inline-block size-[var(--handle-size)] translate-x-0 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
    ].freeze

    SIZE = {
      base: "[--toggle-height:theme(spacing.6)] [--handle-size:theme(spacing.5)] [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.4))]",
      sm: "[--toggle-height:theme(spacing.5)] [--handle-size:theme(spacing.4)] [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.3))]"
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
