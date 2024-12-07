# frozen_string_literal: true

module NitroKit
  module ButtonHelper
    include Variants

    def nk_button(text = nil, **attrs)
      render(NitroKit::Button.new(**attrs)) do
        text || (block_given? ? capture { yield } : nil)
      end
    end

    automatic_variants(Button::VARIANTS, :nk_button)

    # Matches the API of UrlHelper#button_to
    def nk_button_to(name = nil, url_for_options = nil, **attrs, &block)
      url_for_options = name if block_given?

      form_options = attrs.delete(:form) || {}
      form_options.merge!(attrs.slice(:multipart, :method, :authenticity_token, :remote, :enforce_utf8))

      form_tag(url_for_options, form_options) do
        nk_button(name, type: "submit", **attrs)
      end
    end

    automatic_variants(Button::VARIANTS, :nk_button_to)

    # Matches the API of UrlHelper#link_to
    def nk_button_link_to(text = nil, options = nil, **attrs, &block)
      if block_given?
        options = text if block_given?
        text = nil
      end

      href = attrs[:href] || url_target(text, options)

      render(NitroKit::Button.new(**attrs, href:)) do
        text || (block_given? ? yield : "")
      end
    end

    automatic_variants(Button::VARIANTS, :nk_button_link_to)

    def nk_button_group(**attrs, &block)
      render(ButtonGroup.new(**attrs), &block)
    end
  end
end
