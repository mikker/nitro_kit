module IgnitionKit
  module ButtonHelper
    def ik_button(
      text = nil,
      href: nil,
      icon: nil,
      icon_right: nil,
      size: :base,
      type: :button,
      variant: :default,
      **attrs,
      &block
    )
      content = block_given? ? capture(&block) : text

      render(
        IgnitionKit::Button.new(
          href:,
          icon:,
          icon_right:,
          size:,
          type:,
          variant:,
          **attrs
        )
      ) do
        content
      end
    end

    def ik_primary_button(text = nil, **attrs, &block)
      ik_button(text, **attrs, variant: :primary, &block)
    end

    def ik_destructive_button(text = nil, **attrs, &block)
      ik_button(text, **attrs, variant: :destructive, &block)
    end

    def ik_ghost_button(text = nil, **attrs, &block)
      ik_button(text, **attrs, variant: :ghost, &block)
    end
  end
end
