# frozen_string_literal: true

module NitroKit
  class Input < Component
    def initialize(**attrs)
      super(
        attrs,
        class: base_class
      )
    end

    def view_template
      input(**attrs)
    end

    private

    def base_class
      [
        "rounded-md border bg-background border-border text-base px-3 py-2",
        # Focus
        "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
      ]
    end
  end
end
