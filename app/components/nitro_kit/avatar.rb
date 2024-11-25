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
          [
            "inline-flex size-12 overflow-hidden rounded-full",
            size_classes,
            attrs[:class]
          ]
        )
      ) do
        image
      end
    end

    def image
      img(src:, class: "block size-full bg-muted")
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

    # def initials(**attrs)
    #   div(
    #     **attrs,
    #     class: merge(["h-12 w-12 flex items-center justify-center text-white bg-gray-500 rounded-full", attrs[:class]])
    #   ) { yield }
    # end
  end
end
