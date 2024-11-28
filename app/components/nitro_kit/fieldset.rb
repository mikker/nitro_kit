# frozen_string_literal: true

module NitroKit
  class Fieldset < Component
    FIELDSET_BASE = "space-y-6"

    def initialize(legend, **attrs)
      @legend = legend
      @attrs = attrs
    end

    attr_reader :legend, :attrs

    def view_template(&block)
      fieldset(**attrs, class: FIELDSET_BASE, &block)
    end
  end
end
