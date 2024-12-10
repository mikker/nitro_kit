# frozen_string_literal: true

module NitroKit
  module BadgeHelper
    include Variants

    automatic_variants(Badge::VARIANTS, :nk_badge)

    def nk_badge(**attrs, &block)
      render(NitroKit::Badge.new(**attrs), &block)
    end
  end
end
