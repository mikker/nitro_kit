module NitroKit
  class Checkbox < Component
    def initialize(label: nil, id: nil, **attrs)
      super(**attrs)

      @id = id || SecureRandom.hex(4)

      @label = label
    end

    alias :html_label :label

    attr_reader :label, :id

    def view_template
      div(class: merge("isolate inline-flex items-center gap-2", attrs[:class])) do
        html_label(class: "relative flex shrink-0") do
          input(
            id:,
            **attrs,
            type: "checkbox",
            class: merge(
              "peer appearance-none shadow-sm size-4 rounded-sm border text-foreground",
              "checked:bg-primary checked:border-primary",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            )
          )
          checkmark
        end

        if label.present?
          render(Label.new(for: id)) { label }
        end
      end
    end

    private

    def checkmark
      span(
        class: merge(
          "absolute w-full h-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2",
          "text-zinc-50 dark:text-zinc-950 opacity-0 peer-checked:opacity-100 pointer-events-none"
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
