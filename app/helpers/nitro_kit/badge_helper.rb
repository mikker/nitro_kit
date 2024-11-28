# frozen_string_literal: true

module NitroKit
  module BadgeHelper
    include Variants

    automatic_variants(Badge::VARIANTS, :nk_badge)

    def nk_badge(text = nil, **attrs, &block)
      content = text || capture(&block)

      render(NitroKit::Badge.new(**attrs)) do
        content
      end
    end
  end
end
