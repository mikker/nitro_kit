module NitroKit
  module LabelHelper
    def ik_label(name = nil, content_or_options = nil, options = nil, &block)
      if block_given? && content_or_options.is_a?(Hash)
        options = content_or_options = content_or_options.symbolize_keys
      else
        options ||= {}
        options = options.symbolize_keys
      end

      options[:for] = sanitize_to_id(name) unless name.blank? || options.has_key?("for")
      render(Label.new(**options)) { content_or_options || name.to_s.humanize || yield }
    end
  end
end
