module IgnitionKit
  module CardHelper
    CARD_BASE = "rounded-lg border p-6 space-y-6 shadow-sm".freeze

    def card(content = nil, **attrs, &block)
      class_list = merge([CARD_BASE, attrs[:class]])
      content_tag(:div, content || capture(&block), **attrs, class: class_list)
    end
  end
end
