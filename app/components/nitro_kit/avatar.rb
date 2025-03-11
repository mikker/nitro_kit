# frozen_string_literal: true

module NitroKit
  class Avatar < Component
    include Phlex::Rails::Helpers::ImageTag

    def initialize(src_arg = nil, src: nil, size: :md, **attrs)
      @src = src_arg || src
      @size = size

      super(
        attrs,
        class: [container_class, size_classes]
      )
    end

    attr_reader :src, :size

    def view_template(&block)
      div(**attrs) do
        image
      end
    end

    builder_method def image
      image_tag(src, class: image_class)
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
      "inline-flex overflow-hidden rounded-full"
    end

    def image_class
      "block size-full bg-muted"
    end
  end
end
