module NitroKit
  module ButtonHelper
    include Variants

    automatic_variants(Button::VARIANTS, :nk_button)

    def nk_button(
      text = nil,
      href: nil,
      icon: nil,
      icon_right: nil,
      size: :base,
      variant: :default,
      **attrs,
      &block
    )
      if block_given?
        text = capture(&block)
      end

      if href && !href.is_a?(String)
        href = url_for(href)
      end

      render(
        NitroKit::Button.new(
          href:,
          icon:,
          icon_right:,
          variant:,
          size:,
          **attrs
        )
      ) do
        text
      end
    end
  end
end
