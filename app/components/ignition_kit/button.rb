module IgnitionKit
  class Button < Component
    BASE = [
      "inline-flex items-center justify-center rounded-md border gap-2",
      "focus:outline-none focus:ring-[3px] focus:ring-ring",
      "[&_svg]:size-4"
    ].freeze

    VARIANTS = {
      default: ["bg-background text-foreground border-border"],
      primary: ["bg-primary text-white border-primary"],
      destructive: ["bg-destructive text-white border-destructive"],
      ghost: ["bg-transparent text-foreground border-transparent"]
    }.freeze

    SIZES = {
      base: "px-4 py-1.5 font-medium",
      sm: "px-2.5 py-1 font-medium text-sm",
      xs: "px-1.5 py-0.5 font-medium text-xs"
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

      @class_list = merge([BASE, VARIANTS[variant], SIZES[size], attrs[:class]])
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
      render(IgnitionKit::Icon.new(name: icon)) if icon
      yield
      render(IgnitionKit::Icon.new(name: icon_right)) if icon_right
    end
  end
end
