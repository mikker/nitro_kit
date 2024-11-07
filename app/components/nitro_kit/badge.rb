module NitroKit
  class Badge < Component
    BASE = "inline-flex items-center gap-x-1.5 rounded-md font-medium"

    VARIANTS = {
      default: "border border-transparent bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300",
      outline: "border"
    }

    SIZES = {
      sm: "text-xs px-1.5 py-0.5",
      md: "text-sm px-2 py-0.5"
    }

    def initialize(variant: :default, size: :md, **attrs)
      @attrs = attrs

      @class_list = merge(
        [
          BASE,
          VARIANTS[variant],
          SIZES[size],
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
