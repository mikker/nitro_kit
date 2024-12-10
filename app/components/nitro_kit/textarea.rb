# frozen_string_literal: true

module NitroKit
  class Textarea < Component
    def initialize(**attrs)
      super(
        attrs,
        class: default_class
      )
    end

    def view_template
      textarea(**attrs)
    end

    private

    def default_class
      [
        "rounded-md border bg-background border-border text-base px-3 py-2",
        # Focus
        "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
      ]
    end
  end
end
