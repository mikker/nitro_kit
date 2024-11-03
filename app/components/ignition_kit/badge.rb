module IgnitionKit
  class Badge < Component
    BASE = [
      "inline-flex items-center gap-x-1.5 rounded-md px-1.5 py-0.5",
      "text-sm font-medium"
    ].join(" ").freeze

    VARIANTS = {
      default: "bg-[var(--color-zinc-200)] text-[var(--color-zinc-700)]",
      outline: "border"
    }

    def initialize(variant: :default, **attrs)
      @attrs = attrs

      @class_list = merge(
        [
          BASE,
          VARIANTS[variant],
          attrs[:class]
        ]
      )
    end

    attr_reader :color, :attrs, :class_list

    def view_template(&block)
      span(**attrs, class: class_list, &block)
    end
  end
end

