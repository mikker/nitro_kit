module NitroKit
  module ButtonHelper
    include Variants

    automatic_variants(Button::VARIANTS, :nk_button)

    def nk_button(
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
      if block_given?
        content = capture(&block)
        href = text_or_href
      elsif href.nil? && icon
        content = nil
        href = text_or_href
      else
        content = text_or_href
      end

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
