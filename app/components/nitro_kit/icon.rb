# frozen_string_literal: true

module NitroKit
  class Icon < Component
    include Phlex::Rails::Helpers::ContentTag
    include LucideRails::RailsHelper

    SIZE = {
      sm: "size-4",
      base: "size-5"
    }

    def initialize(name:, size: :base, **attrs)
      @name = name
      @size = size
      @attrs = attrs
    end

    attr_reader :name, :size

    def view_template
      lucide_icon(name, **attrs, class: merge([SIZE[size], attrs[:class]]))
    end
  end
end
