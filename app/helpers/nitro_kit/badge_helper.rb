# frozen_string_literal: true

module NitroKit
  module BadgeHelper
    include Variants

    automatic_variants(Badge::VARIANTS, :nk_badge)

    def nk_badge(text = nil, **attrs, &block)
      render(NitroKit::Badge.from_template(text, **attrs), &block)
    end
  end
end
