module IgnitionKit
  class Checkbox < Component
    CONTAINER_BASE = "inline-flex items-center"
    LABEL_BASE = "relative flex items-center shink-0"

    INPUT_BASE = [
      "peer appearance-none shadow size-5 rounded border-zinc-400 text-foreground",
      "checked:bg-primary checked:border-primary checked:text-white",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    ].freeze

    SPAN_BASE = [
      "absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2",
      "text-white opacity-0 peer-checked:opacity-100 pointer-events-none"
    ].freeze

    SVG_BASE = "h-3.5 w-3.5"

    def initialize(name, value = "1", label: nil, **attrs)
      @name = name
      @label_text = label
      @attrs = attrs.symbolize_keys
      @class_list = merge([INPUT_BASE, @attrs.delete(:class)])
    end

    attr_reader(
      :name,
      :value,
      :label_text
    )

    def view_template
      div(class: CONTAINER_BASE) do
        label(class: LABEL_BASE) do
          input(**attrs, type: "checkbox", class: class_list)

          span(class: SPAN_BASE) do
            svg(
              class: SVG_BASE,
              view_box: "0 0 20 20",
              xmlns: "http://www.w3.org/2000/svg",
              fill: "currentColor",
              stroke: "currentColor",
              stroke_width: 1
            ) do |svg|
              svg.path(
                :"fill-rule" => "evenodd",
                :d => "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z",
                :"clip-rule" => "evenodd"
              )
            end
          end
        end

        if label_text
          label(class: "ml-2", for: attrs[:id]) { label_text }
        end
      end
    end
  end
end
