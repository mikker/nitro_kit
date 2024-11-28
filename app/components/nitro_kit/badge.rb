# frozen_string_literal: true

module NitroKit
  class Badge < Component
    BADGE = "inline-flex items-center gap-x-1.5 rounded-md font-medium"

    VARIANTS = {
      default: "border border-transparent bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300",
      outline: "border"
    }

    SIZES = {
      sm: "text-xs px-1.5 py-0.5",
      md: "text-sm px-2 py-0.5"
    }

    def initialize(variant: :default, size: :md, **attrs)
      super(**attrs)

      @variant = variant
      @size = size
    end

    attr_reader :variant, :size

    def view_template
      span(
        **attrs,
        class: merge(BADGE, VARIANTS[variant], SIZES[size], attrs[:class])
      ) { yield }
    end
  end
end
