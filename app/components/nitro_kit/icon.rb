# frozen_string_literal: true

module NitroKit
  class Icon < Component
    include Phlex::Rails::Helpers::ContentTag
    include LucideRails::RailsHelper

    def initialize(name:, size: :md, **attrs)
      @name = name
      @size = size

      super(
        attrs,
        class: size_class
      )
    end

    attr_reader :name, :size

    def view_template
      lucide_icon(name, **attrs)
    end

    private

    def size_class
      case size
      when :sm
        "size-4"
      when :md
        "size-5"
      else
        raise ArgumentError, "Unknown size `#{size}'"
      end
    end
  end
end
