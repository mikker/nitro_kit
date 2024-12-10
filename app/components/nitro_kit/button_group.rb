# frozen_string_literal: true

module NitroKit
  class ButtonGroup < Component
    def initialize(**attrs)
      super(
        attrs,
        class: [
          "flex -space-x-px isolate",
          # Remove rounded corners from middle buttons
          "[&>*:not(:first-child):not(:last-child)]:rounded-none [&>*:first-child:not(:last-child)]:rounded-r-none [&>*:last-child:not(:first-child)]:rounded-l-none",
          # Put focused button on top
          "[&>*]:focus:z-10"
        ]
      )
    end

    def view_template
      div(**attrs) do
        yield
      end
    end
  end
end
