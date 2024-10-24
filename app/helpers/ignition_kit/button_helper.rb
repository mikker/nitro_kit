module IgnitionKit
  module ButtonHelper
    def button(
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

    def primary_button(text = nil, **attrs, &block)
      button(text, **attrs, variant: :primary, &block)
    end

    def destructive_button(text = nil, **attrs, &block)
      button(text, **attrs, variant: :destructive, &block)
    end

    def ghost_button(text = nil, **attrs, &block)
      button(text, **attrs, variant: :ghost, &block)
    end
  end
end
