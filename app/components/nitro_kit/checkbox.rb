module NitroKit
  class Checkbox < Component
    def initialize(label: nil, id: nil, wrapper: {}, **attrs)
      @id = id || "nk--" + SecureRandom.hex(4)
      @label = label
      @wrapper = wrapper

      super(
        attrs,
        id: @id,
        type: "checkbox",
        class: input_class
      )
    end

    alias :html_label :label

    attr_reader :label, :id, :wrapper

    def view_template
      div(**mattr(wrapper, class: wrapper_class)) do
        html_label(
          class: "inline-grid *:[grid-area:1/1] shrink-0 place-items-center group/checkbox has-checked:not-has-indeterminate:[&>[data-check]]:visible has-indeterminate:[&>[data-indeterminate]]:visible"
        ) do
          input(**attrs)
          checkmark
          dash
        end

        if label.present? || block_given?
          render(Label.new(for: id)) do
            label || (block_given? ? yield : nil)
          end
        end
      end
    end

    private

    def checkmark
      svg(
        class: merge_class(svg_class, "invisible"),
        viewbox: "0 0 16 16",
        fill: "none",
        stroke: "currentColor",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        stroke_width: 3,
        data: {check: ""}
      ) do |svg|
        svg.path(d: "M 3 8 L 6 12 L 13 5")
      end
    end

    def dash
      svg(
        class: merge_class(svg_class, "invisible"),
        viewbox: "0 0 16 16",
        fill: "none",
        stroke: "currentColor",
        stroke_linecap: "round",
        stroke_width: 3,
        data: {indeterminate: ""}
      ) do |svg|
        svg.line(x1: "3", y1: "8", x2: "13", y2: "8")
      end
    end

    def input_class
      [
        "appearance-none shadow-sm size-4 rounded-sm border text-foreground",
        "checked:bg-primary checked:border-primary indeterminate:bg-primary indeterminate:border-primary",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring ring-offset-2 ring-offset-background",
        "disabled:pointer-events-none"
      ]
    end

    def svg_class
      "size-3 text-zinc-50 dark:text-zinc-950 pointer-events-none invisible"
    end

    def wrapper_class
      [
        "isolate inline-flex items-center gap-2",
        "has-disabled:opacity-70"
      ]
    end
  end
end
