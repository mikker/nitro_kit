module IgnitionKit
  class Badge < Component
    BASE = [
      "inline-flex items-center gap-x-1.5 rounded-md px-1.5 py-0.5",
      "text-sm font-medium",
    ].join(" ").freeze

    COLORS = {
      slate: "bg-[var(--color-slate-200)] text-[var(--color-slate-700)]",
      gray: "bg-[var(--color-gray-200)] text-[var(--color-gray-700)]",
      zinc: "bg-[var(--color-zinc-200)] text-[var(--color-zinc-700)]",
      neutral: "bg-[var(--color-neutral-200)] text-[var(--color-neutral-700)]",
      stone: "bg-[var(--color-stone-200)] text-[var(--color-stone-700)]",
      red: "bg-[var(--color-red-200)] text-[var(--color-red-700)]",
      orange: "bg-[var(--color-orange-200)] text-[var(--color-orange-700)]",
      amber: "bg-[var(--color-amber-200)] text-[var(--color-amber-700)]",
      yellow: "bg-[var(--color-yellow-200)] text-[var(--color-yellow-700)]",
      lime: "bg-[var(--color-lime-200)] text-[var(--color-lime-700)]",
      green: "bg-[var(--color-green-200)] text-[var(--color-green-700)]",
      emerald: "bg-[var(--color-emerald-200)] text-[var(--color-emerald-700)]",
      teal: "bg-[var(--color-teal-200)] text-[var(--color-teal-700)]",
      cyan: "bg-[var(--color-cyan-200)] text-[var(--color-cyan-700)]",
      sky: "bg-[var(--color-sky-200)] text-[var(--color-sky-700)]",
      blue: "bg-[var(--color-blue-200)] text-[var(--color-blue-700)]",
      indigo: "bg-[var(--color-indigo-200)] text-[var(--color-indigo-700)]",
      violet: "bg-[var(--color-violet-200)] text-[var(--color-violet-700)]",
      purple: "bg-[var(--color-purple-200)] text-[var(--color-purple-700)]",
      fuchsia: "bg-[var(--color-fuchsia-200)] text-[var(--color-fuchsia-700)]",
      pink: "bg-[var(--color-pink-200)] text-[var(--color-pink-700)]",
      rose: "bg-[var(--color-rose-200)] text-[var(--color-rose-700)]"
    }

    def initialize(color: :gray, **attrs)
      @color = color
      @attrs = attrs

      @class_list = merge([
        BASE,
        COLORS[color],
        attrs[:class]
      ])
    end

    attr_reader :color, :attrs, :class_list

    def view_template(&block)
      span(**attrs, class: class_list, &block)
    end
  end
end