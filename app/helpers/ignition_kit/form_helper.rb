module IgnitionKit
  module FormHelper
    class Original
      class << self
        include ActionView::Helpers::FormHelper
      end
    end

    def label(object_name, method, content_or_options = nil, options = nil, &block)
      options ||= {}

      content_is_options = content_or_options.is_a?(Hash)
      if content_is_options
        options.merge!(content_or_options)
        content = nil
      else
        content = content_or_options
      end

      Original.label(object_name, method, content, options, &block)
    end
  end
end
