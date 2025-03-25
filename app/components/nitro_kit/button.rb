# frozen_string_literal: true

module NitroKit
  class Button < Component
    VARIANTS = %i[default primary destructive ghost]

    def initialize(
      text = nil,
      href: nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_right: nil,
      **attrs
    )
      @text = text
      @href = href
      @icon = icon
      @icon_right = icon_right
      @size = size
      @variant = variant

      super(
        attrs,
        class: [
          base_class,
          variant_class,
          size_class
        ]
      )
    end

    attr_reader(
      :text,
      :href,
      :icon,
      :icon_right,
      :size,
      :variant
    )

    def view_template(&block)
      if href
        a(href:, **attrs) do
          contents(&block)
        end
      else
        button(type: :button, **attrs) do
          contents(&block)
        end
      end
    end

    private

    def contents(&block)
      has_content = text.present? || block_given?

      if !has_content
        return render(Icon.new(icon))
      end

      render(Icon.new(icon)) if icon

      if block_given?
        yield
      else
        span { plain(text) }
      end

      render(Icon.new(icon_right)) if icon_right
    end

    def base_class
      [
        "inline-flex items-center cursor-pointer shrink-0 justify-center rounded-md border gap-2 font-medium select-none",
        # Disabled
        "disabled:opacity-70 disabled:pointer-events-none",
        # Focus
        "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-offset-2 focus-visible:ring-ring ring-offset-background",
        # Icon
        "[&_svg]:pointer-events-none [&_svg]:shrink-0"
      ]
    end

    def variant_class
      case variant
      when :default
        [
          "bg-background text-foreground border-border",
          "hover:bg-zinc-50 dark:hover:bg-zinc-900"
        ]
      when :primary
        [
          "bg-primary text-primary-foreground border-primary",
          "hover:bg-primary/90 dark:hover:bg-primary/90"
        ]
      when :destructive
        [
          "bg-destructive text-destructive-foreground border-destructive",
          "hover:bg-destructive/90 dark:hover:bg-destructive/90",
          "disabled:text-destructive-foreground/80"
        ]
      when :ghost
        [
          "bg-transparent text-foreground border-transparent",
          "hover:bg-zinc-200/50 dark:hover:bg-zinc-900",
          "disabled:text-muted-content"
        ]
      else
        raise ArgumentError, "Unknown variant `#{variant}'"
      end
    end

    def size_class
      case size
      when :xs
        "px-1.5 h-6 text-xs [&_svg]:size-3"
      when :sm
        [
          "px-2.5 h-7 text-sm [&_svg]:size-4",
          "[&_svg:first-child:last-child]:-mx-1"
        ]
      when :md
        [
          "px-4 h-10 text-base [&_svg]:size-4",
          # If icon only, make square
          "[&_svg:first-child:last-child]:-mx-1"
        ]
      when :lg
        [
          "px-5 h-11 text-lg [&_svg]:size-5",
          # If icon only, make square
          "[&_svg:first-child:last-child]:-mx-2"
        ]
      else
        raise ArgumentError, "Unknown size `#{size}'"
      end
    end
  end
end
