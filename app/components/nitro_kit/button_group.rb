module NitroKit
  class ButtonGroup < Component
    def view_template(&block)
      div(
        class: merge(
          [
            "flex -space-x-px isolate",
            # Remove rounded corners from middle buttons
            "[&>*:not(:first-child):not(:last-child)]:rounded-none [&>*:first-child:not(:last-child)]:rounded-r-none [&>*:last-child:not(:first-child)]:rounded-l-none",
            # Put focused button on top
            "[&>*]:focus:z-10",
            attrs[:class]
          ]
        ),
        &block
      )
    end
  end
end
