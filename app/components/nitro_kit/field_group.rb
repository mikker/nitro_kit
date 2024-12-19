# frozen_string_literal: true

module NitroKit
  class FieldGroup < Component
    def initialize(**attrs)
      super(attrs, class: base_class, data: {slot: "control"})
    end

    def view_template(&block)
      div(**attrs, &block)
    end

    private

    def base_class
      "space-y-6"
    end
  end
end
