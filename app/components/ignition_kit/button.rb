module IgnitionKit
  class Button < Component
    BASE = [
      "inline-flex items-center shrink-0 justify-center rounded-md border gap-2 font-medium",
      # Focus
      "focus:outline-none focus:ring-[3px] focus:ring-offset-2 focus:ring-ring",

      # Icon
      "[&_svg]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",

      # If icon alone, make square
      "[&_svg:first-child:last-child]:-mx-2"
    ].freeze

    VARIANTS = {
      default: ["bg-background text-foreground border-border"],
      primary: ["bg-primary text-white dark:text-zinc-950 border-primary"],
      destructive: ["bg-destructive text-white border-destructive"],
      ghost: ["bg-transparent text-foreground border-transparent"]
    }.freeze

    SIZES = {
      base: "px-4 h-9",
      sm: "px-2.5 h-7 text-sm",
      xs: "px-1.5 h-6 text-xs"
    }

    def initialize(
      href: nil,
      icon: nil,
      icon_right: nil,
      size: :base,
      type: :button,
      variant: :default,
      **attrs
    )
      @href = href
      @icon = icon
      @icon_right = icon_right
      @size = size
      @type = type
      @variant = variant
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

    attr_reader(
      :class_list,
      :href,
      :icon,
      :icon_right,
      :size,
      :type,
      :variant,
      :attrs
    )

    def view_template(&block)
      if href
        a(href:, **attrs, class: class_list) do
          contents(&block)
        end
      else
        button(type:, **attrs, class: class_list) do
          contents(&block)
        end
      end
    end

    private

    def contents
      text = safe(capture { yield })
      has_text = text.to_s.present?

      if !icon && has_text && !icon_right
        return text
      elsif icon && !has_text && !icon_right
        return render(Icon.new(name: icon))
      end

      render(Icon.new(name: icon)) if icon
      span { text }
      render(Icon.new(name: icon_right)) if icon_right
    end
  end
end
