# frozen_string_literal: true

module NitroKit
  class Label < Component
    def view_template
      label(
        **attrs,
        class: merge("text-sm font-medium select-none", attrs[:class])
      ) { yield }
    end
  end
end
