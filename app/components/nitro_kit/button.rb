module NitroKit
  class Button < Component
    BASE = [
      "inline-flex items-center cursor-pointer shrink-0 justify-center rounded-md border gap-2 font-medium",
      # Disabled
      "disabled:opacity-70 disabled:pointer-events-none",
      # Focus
      "focus:outline-none focus:ring-[3px] focus:ring-offset-2 focus:ring-ring ring-offset-background",
      # Icon
      "[&_svg]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
      # If icon only, make square
      "[&_svg:first-child:last-child]:-mx-2"
    ].freeze

    VARIANTS = {
      default: [
        "bg-background text-foreground",
        "hover:bg-zinc-50 dark:hover:bg-zinc-900"
      ],
      primary: [
        "bg-primary text-white dark:text-zinc-950 border-primary",
        "hover:bg-primary/90 dark:hover:bg-primary/90"
      ],
      destructive: [
        "bg-destructive text-white border-destructive",
        "hover:bg-destructive/90 dark:hover:bg-destructive/90",
        "disabled:text-white/80"
      ],
      ghost: [
        "bg-transparent text-foreground border-transparent",
        "hover:bg-zinc-100 dark:hover:bg-zinc-900",
        "disabled:text-muted-foreground"
      ]
    }.freeze

    SIZES = {
      base: "px-4 h-9",
      sm: "px-2.5 h-7 text-sm",
      xs: "px-1.5 h-6 text-xs"
    }.freeze

    def initialize(
      href: nil,
      icon: nil,
      icon_right: nil,
      size: :base,
      type: :button,
      variant: :default,
      **attrs
    )
      super(**attrs)

      @href = href
      @icon = icon
      @icon_right = icon_right
      @size = size
      @type = type
      @variant = variant
    end

    attr_reader(
      :href,
      :icon,
      :icon_right,
      :size,
      :type,
      :variant
    )

    def view_template(&block)
      class_list = merge(
        [
          BASE,
          VARIANTS[variant],
          SIZES[size],
          attrs[:class]
        ]
      )

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
