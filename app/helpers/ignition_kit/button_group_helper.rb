module IgnitionKit
  module ButtonGroupHelper
    def merge(*)
      IgnitionKit::Component.merge(*)
    end

    def button_group(**attrs, &block)
      class_list = merge(
        [
          "flex group/buttons -space-x-px isolate",
          # Remove rounded corners from middle buttons
          "[&>*:not(:first-child):not(:last-child)]:rounded-none [&>*:first-child:not(:last-child)]:rounded-r-none [&>*:last-child:not(:first-child)]:rounded-l-none",
          # Put focused button on top
          "[&>*]:focus:z-10"
        ]
      )

      tag.div(class: class_list, &block)
    end
  end
end
