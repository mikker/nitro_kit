module IgnitionKit
  # These need JS to toggle the stats. Maybe we need to implement these as checkboxes to work with forms, not sure. Maybe include a hidden_field above to make sure we send an "off" value when unchecked similar to the checkbox helpers.
  module ToggleHelper
    TOGGLE_BASE = [
      "relative inline-flex h-[var(--toggle-height)] w-[calc(var(--handle-size)*2)] flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out",
      "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
      "bg-[var(--bg-color)] [&[aria-checked='true']]:bg-[var(--bg-color-checked)]",
    ].join(" ").freeze

    HANDLE_BASE = [
      "pointer-events-none inline-block size-[var(--handle-size)] translate-x-0 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
    ].join(" ").freeze

    COLOR = {
      primary: "[--bg-color:var(--color-zinc-200)] [--bg-color-checked:var(--color-primary)]",
      slate: "[--bg-color:var(--color-slate-200)] [--bg-color-checked:var(--color-slate-400)]",
      gray: "[--bg-color:var(--color-gray-200)] [--bg-color-checked:var(--color-gray-400)]",
      zinc: "[--bg-color:var(--color-zinc-200)] [--bg-color-checked:var(--color-zinc-400)]",
      neutral: "[--bg-color:var(--color-neutral-200)] [--bg-color-checked:var(--color-neutral-400)]",
      stone: "[--bg-color:var(--color-stone-200)] [--bg-color-checked:var(--color-stone-400)]",
      red: "[--bg-color:var(--color-red-200)] [--bg-color-checked:var(--color-red-400)]",
      orange: "[--bg-color:var(--color-orange-200)] [--bg-color-checked:var(--color-orange-400)]",
      amber: "[--bg-color:var(--color-amber-200)] [--bg-color-checked:var(--color-amber-400)]",
      yellow: "[--bg-color:var(--color-yellow-200)] [--bg-color-checked:var(--color-yellow-400)]",
      lime: "[--bg-color:var(--color-lime-200)] [--bg-color-checked:var(--color-lime-400)]",
      green: "[--bg-color:var(--color-green-200)] [--bg-color-checked:var(--color-green-400)]",
      emerald: "[--bg-color:var(--color-emerald-200)] [--bg-color-checked:var(--color-emerald-400)]",
      teal: "[--bg-color:var(--color-teal-200)] [--bg-color-checked:var(--color-teal-400)]",
      cyan: "[--bg-color:var(--color-cyan-200)] [--bg-color-checked:var(--color-cyan-400)]",
      sky: "[--bg-color:var(--color-sky-200)] [--bg-color-checked:var(--color-sky-400)]",
      blue: "[--bg-color:var(--color-blue-200)] [--bg-color-checked:var(--color-blue-400)]",
      indigo: "[--bg-color:var(--color-indigo-200)] [--bg-color-checked:var(--color-indigo-400)]",
      violet: "[--bg-color:var(--color-violet-200)] [--bg-color-checked:var(--color-violet-400)]",
      purple: "[--bg-color:var(--color-purple-200)] [--bg-color-checked:var(--color-purple-400)]",
      fuchsia: "[--bg-color:var(--color-fuchsia-200)] [--bg-color-checked:var(--color-fuchsia-400)]",
      pink: "[--bg-color:var(--color-pink-200)] [--bg-color-checked:var(--color-pink-400)]",
      rose: "[--bg-color:var(--color-rose-200)] [--bg-color-checked:var(--color-rose-400)]"
    }

    SIZE = {
      base: "[--toggle-height:theme(spacing.6)] [--handle-size:theme(spacing.5)] [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.4))]",
      sm: "[--toggle-height:theme(spacing.5)] [--handle-size:theme(spacing.4)] [&[aria-checked=true]_[data-slot=handle]]:translate-x-[calc(theme(spacing.3))]"
    }

    INPUT_BASE = "sr-only peer"

    def toggle(
      name,
      checked: false,
      disabled: false,
      color: :primary,
      size: :base,
      description: nil,
      **attrs
    )
      description ||= name

      data = {controller: "toggle", **attrs.fetch(:data, {})}

      class_list = merge(
        [
          TOGGLE_BASE,
          SIZE[size],
          COLOR[color],
          attrs.delete(:class)
        ]
      )

      tag.button(
        **attrs,
        type: "button",
        class: class_list,
        data: data,
        role: "switch",
        aria: {checked: checked}
      ) do
        concat(tag.span(class: "sr-only") { description })
        concat(tag.span(aria: {hidden: true}, class: HANDLE_BASE, data: {slot: "handle"}))
      end
    end
  end
end
