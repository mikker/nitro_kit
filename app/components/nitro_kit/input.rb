module NitroKit
  class Input < Component
    def view_template
      input(
        **attrs,
        class: merge(default_class, attrs[:class])
      )
    end

    private

    def default_class
      [
        "rounded-md border bg-background border-border text-base px-3 py-2",
        "w-full",
        # Focus
        "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
      ]
    end
  end
end
