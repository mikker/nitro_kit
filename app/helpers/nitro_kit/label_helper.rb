# frozen_string_literal: true

module NitroKit
  module LabelHelper
    def nk_label(compat_object_name = nil, compat_method = nil, content_or_options = nil, **attrs, &block)
      name = field_name(compat_object_name, compat_method)

      case content_or_options
      when String
        text = content_or_options
      when Hash
        text = nil
        attrs.merge!(content_or_options)
      end

      render(Label.new(text, for: name, **attrs), &block)
    end
  end
end
