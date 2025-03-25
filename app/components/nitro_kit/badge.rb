# frozen_string_literal: true

module NitroKit
  class Badge < Component
    VARIANTS = %i[default outline]

    def initialize(text = nil, variant: :default, size: :md, color: :gray, **attrs)
      @text = text
      @variant = variant
      @size = size
      @color = color

      super(
        attrs,
        class: [
          base_class,
          variant_class,
          size_class
        ]
      )
    end

    attr_reader :text, :variant, :size, :color

    def view_template(&block)
      span(**attrs) do
        text_or_block(text, &block)
      end
    end

    private

    def base_class
      "inline-flex items-center gap-x-1.5 rounded-md font-medium whitespace-nowrap"
    end

    def variant_class
      case variant
      when :default
        color_class
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

    def color_class
      case color
      when :gray
        "text-zinc-700 dark:text-zinc-200 bg-zinc-400/15 dark:bg-zinc-400/40"
      when :red
        "text-red-900 dark:text-red-200 bg-red-300/50 dark:bg-red-400/40"
      when :orange
        "text-orange-700 dark:text-orange-200 bg-orange-400/20 dark:bg-orange-400/40"
      when :amber
        "text-amber-700 dark:text-amber-200 bg-amber-400/20 dark:bg-amber-400/40"
      when :yellow
        "text-yellow-900 dark:text-yellow-200 bg-yellow-400/40 dark:bg-yellow-400/40"
      when :lime
        "text-lime-700 dark:text-lime-200 bg-lime-400/20 dark:bg-lime-400/40"
      when :green
        "text-green-800 dark:text-green-200 bg-green-500/20 dark:bg-green-400/40"
      when :emerald
        "text-emerald-700 dark:text-emerald-200 bg-emerald-400/20 dark:bg-emerald-400/40"
      when :teal
        "text-teal-700 dark:text-teal-200 bg-teal-400/20 dark:bg-teal-400/40"
      when :cyan
        "text-cyan-700 dark:text-cyan-200 bg-cyan-400/20 dark:bg-cyan-400/40"
      when :sky
        "text-sky-700 dark:text-sky-200 bg-sky-400/20 dark:bg-sky-400/40"
      when :blue
        "text-blue-700 dark:text-blue-200 bg-blue-400/20 dark:bg-blue-400/40"
      when :indigo
        "text-indigo-700 dark:text-indigo-200 bg-indigo-400/20 dark:bg-indigo-400/40"
      when :violet
        "text-violet-700 dark:text-violet-200 bg-violet-400/20 dark:bg-violet-400/40"
      when :purple
        "text-purple-700 dark:text-purple-200 bg-purple-400/20 dark:bg-purple-400/40"
      when :fuchsia
        "text-fuchsia-700 dark:text-fuchsia-200 bg-fuchsia-400/20 dark:bg-fuchsia-400/40"
      when :pink
        "text-pink-700 dark:text-pink-200 bg-pink-400/20 dark:bg-pink-400/40"
      when :rose
        "text-rose-700 dark:text-rose-200 bg-rose-400/20 dark:bg-rose-400/40"
      else
        raise ArgumentError, "Unknown color `#{color}'"
      end
    end
  end
end
