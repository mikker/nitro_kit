# frozen_string_literal: true

module NitroKit
  class Label < Component
    def initialize(**attrs)
      super(
        attrs,
        class: "text-sm font-medium select-none"
      )
    end

    def view_template
      label(**attrs) { yield }
    end
  end
end
