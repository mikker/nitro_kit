module IgnitionKit
  class Checkbox < Component
    include ActionView::Helpers::FormTagHelper

    def initialize(name, value: "1", label: nil, **attrs)
      super(**attrs)

      @name = name
      @label_text = label
    end

    attr_reader(
      :name,
      :value,
      :label_text
    )

    def view_template
      div(class: merge(["inline-flex items-center gap-2", class_list])) do
        label(class: "relative flex shrink-0") do
          input(
            **attrs,
            type: "checkbox",
            class: class_names(
              "peer appearance-none shadow size-5 rounded border-zinc-400 text-foreground",
              "checked:bg-primary checked:border-primary checked:text-white",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            )
          )
          checkmark
        end

        if label_text.present?
          render(Label.new(for: attrs[:id])) { label_text }
        end
      end
    end

    private

    def checkmark
      span(
        class: merge(
          [
            "absolute w-full h-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2",
            "text-zinc-50 dark:text-zinc-950 opacity-0 peer-checked:opacity-100 pointer-events-none"
          ]
        )
      ) do
        svg(
          class: "size-full",
          viewbox: "0 0 20 20",
          fill: "currentColor",
          stroke: "currentColor",
          stroke_width: 1
        ) do |svg|
          svg.path(
            "d" => "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
          )
        end
      end
    end
  end
end
