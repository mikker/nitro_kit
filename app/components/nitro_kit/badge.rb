# frozen_string_literal: true

module NitroKit
  class Badge < Component
    VARIANTS = %i[default outline]

    def initialize(variant: :default, size: :md, **attrs)
      super(**attrs)

      @variant = variant
      @size = size
    end

    attr_reader :variant, :size

    def view_template
      span(
        **attrs,
        class: merge(
          base_class,
          variant_class,
          size_class,
          attrs[:class]
        )
      ) { yield }
    end

    private

    def base_class
      "inline-flex items-center gap-x-1.5 rounded-md font-medium"
    end

    def variant_class
      case variant
      when :default
        "bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300"
      when :outline
        "border"
      else
        raise ArgumentError, "Invalid variant: #{variant}"
      end
    end

    def size_class
      case size
      when :sm
        "text-xs px-1.5 py-0.5"
      when :md
        "text-sm px-2 py-0.5"
      else
        raise ArgumentError, "Invalid size: #{size}"
      end
    end
  end
end
