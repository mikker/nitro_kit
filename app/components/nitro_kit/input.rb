module NitroKit
  INPUT = [
    "rounded-md border bg-background border-border text-base px-3 py-2",
    "focus:outline-none focus:ring-2 focus:ring-primary",
    ""
  ].freeze

  class Input < Component
    def view_template
      input(
        **attrs,
        class: merge(INPUT, attrs[:class])
      )
    end
  end
end
