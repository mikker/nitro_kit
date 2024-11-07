module NitroKit
  module ButtonHelper
    include Variants

    automatic_variants(Button::VARIANTS, :ik_button)

    def ik_button(
      text_or_href = nil,
      href = nil,
      icon: nil,
      icon_right: nil,
      size: :base,
      type: :button,
      variant: :default,
      **attrs,
      &block
    )
      content = block_given? ? capture(&block) : text_or_href
      href = text_or_href if href.nil? && block_given?

      if href && !href.is_a?(String)
        href = url_for(href)
      end

      render(
        NitroKit::Button.new(
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
  end
end
