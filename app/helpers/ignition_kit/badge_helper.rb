module IgnitionKit
  module BadgeHelper
    def ik_badge(text = nil, **attrs, &block)
      content = text || capture(&block)

      render(IgnitionKit::Badge.new(**attrs)) do
        content
      end
    end
  end
end
