# frozen_string_literal: true

module NitroKit
  module LabelHelper
    def nk_label(**attrs, &block)
      render(Label.new(**attrs), &block)
    end

    # Matches the API of ActionView::Helpers::FormTagHelper
    def nk_label_tag(name = nil, content_or_options = nil, **attrs, &block)
      if block_given? && content_or_options.is_a?(Hash)
        attrs = content_or_options = content_or_options.symbolize_keys
      else
        attrs ||= {}
        attrs = attrs.symbolize_keys
      end

      attrs[:for] = sanitize_to_id(name) unless name.blank? || attrs.has_key?("for")

      nk_label(**attrs) { content_or_options || name.to_s.humanize || yield }
    end
  end
end
