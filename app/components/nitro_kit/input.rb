module NitroKit
  INPUT = [
    "rounded-md border bg-background border-border text-base px-3 py-2",
    "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
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
