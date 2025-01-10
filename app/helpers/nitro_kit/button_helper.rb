# frozen_string_literal: true

module NitroKit
  module ButtonHelper
    include Variants

    def nk_button(text = nil, **attrs, &block)
      render(NitroKit::Button.new(text, **attrs), &block)
    end

    automatic_variants(Button::VARIANTS, :nk_button)

    # Matches the API of UrlHelper#button_to
    def nk_button_to(name = nil, url_for_options = nil, **attrs, &block)
      url_for_options = name if block_given?

      form_options = attrs.delete(:form) || {}
      form_options.merge!(attrs.slice(:multipart, :data, :method, :authenticity_token, :remote, :enforce_utf8))

      form_tag(url_for_options, form_options) do
        nk_button(name, type: "submit", **attrs, &block)
      end
    end

    automatic_variants(Button::VARIANTS, :nk_button_to)

    # Matches the API of UrlHelper#link_to
    def nk_button_link_to(*args, **attrs, &block)
      case args.length
      when 1
        options, text = args
      when 2
        text, options = args
      else
        raise ArgumentError, "1..2 arguments expected, got #{args.length}"
      end

      href = attrs[:href] || url_target(text, options)

      render(NitroKit::Button.new(text, **attrs, href:), &block)
    end

    automatic_variants(Button::VARIANTS, :nk_button_link_to)

    def nk_button_group(**attrs, &block)
      render(ButtonGroup.new(**attrs), &block)
    end
  end
end
