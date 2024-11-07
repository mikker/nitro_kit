module NitroKit
  module BadgeHelper
    include Variants

    automatic_variants(Badge::VARIANTS, :ik_badge)

    def ik_badge(text = nil, **attrs, &block)
      content = text || capture(&block)

      render(NitroKit::Badge.new(**attrs)) do
        content
      end
    end
  end
end
