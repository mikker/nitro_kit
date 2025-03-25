# frozen_string_literal: true

module NitroKit
  class Icon < Component
    register_output_helper :lucide_icon

    def initialize(name, size: :md, **attrs)
      @name = name
      @size = size

      super(
        attrs,
        class: size_class,
        stroke_width: 1.5
      )
    end

    attr_reader :name, :size

    def view_template
      lucide_icon(name, **dasherized_attrs)
    end

    private

    def size_class
      case size
      when :xs
        "size-3"
      when :sm
        "size-4"
      when :md
        "size-5"
      when :lg
        "size-7"
      else
        raise ArgumentError, "Unknown size `#{size}'"
      end
    end

    def dasherized_attrs
      attrs.transform_keys { |k| k.to_s.dasherize }
    end
  end
end
