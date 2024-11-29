# frozen_string_literal: true

module NitroKit
  class Avatar < Component
    include ActionView::Helpers::AssetUrlHelper

    def initialize(src = nil, size: :md, **attrs)
      super(**attrs)
      @src = image_path(src || attrs[:src])
      @size = size
    end

    attr_reader :src, :size

    def view_template(&block)
      div(
        **attrs,
        class: merge(
          container_class,
          size_classes,
          attrs[:class]
        )
      ) do
        image
      end
    end

    def image
      img(src:, class: image_class)
    end

    private

    def size_classes
      case size
      when :sm
        "size-8"
      when :md
        "size-12"
      when :lg
        "size-16"
      else
        raise ArgumentError, "Invalid size: #{size}"
      end
    end

    def container_class
      "inline-flex size-12 overflow-hidden rounded-full"
    end

    def image_class
      "block size-full bg-muted"
    end
  end
end
