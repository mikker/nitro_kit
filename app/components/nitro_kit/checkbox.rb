module NitroKit
  class Checkbox < Component
    def initialize(label: nil, id: nil, **attrs)
      @id = id || "nk--" + SecureRandom.hex(4)
      @label = label

      super(
        attrs,
        id: @id,
        type: "checkbox",
        class: input_class
      )
    end

    alias :html_label :label

    attr_reader :label, :id

    def view_template
      div(class: wrapper_class) do
        html_label(
          class: "inline-grid *:[grid-area:1/1] shrink-0 place-items-center group/checkbox"
        ) do
          input(**attrs)
          checkmark
          dash
        end

        if label.present? || block_given?
          render(Label.new(for: id)) { label || yield }
        end
      end
    end

    private

    def checkmark
      svg(
        class: merge_class(svg_class, "group-has-[:checked]/checkbox:visible"),
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

    def dash
      svg(
        class: merge_class(svg_class, "group-has-[:indeterminate]/checkbox:visible"),
        viewbox: "0 0 20 20",
        fill: "none",
        stroke: "currentColor",
        stroke_linecap: "round",
        stroke_width: 3
      ) do |svg|
        svg.line(x1: "5", y1: "10", x2: "15", y2: "10")
      end
    end

    def input_class
      [
        "appearance-none shadow-sm size-4 rounded-sm border text-foreground",
        "checked:bg-primary checked:border-primary indeterminate:bg-primary indeterminate:border-primary",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring ring-offset-2 ring-offset-background"
      ]
    end

    def svg_class
      "size-4 text-zinc-50 [&>svg]:size-full dark:text-zinc-950 pointer-events-none invisible"
    end

    def wrapper_class
      "isolate inline-flex items-center gap-2"
    end
  end
end
