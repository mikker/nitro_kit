module NitroKit
  class Checkbox < Component
    def initialize(label: nil, id: nil, **attrs)
      @id = id || "nk--" + SecureRandom.hex(4)
      @label = label

      super(
        attrs,
        id: @id,
        type: "checkbox",
        class: [
          "peer appearance-none shadow-sm size-4 rounded-sm border text-foreground",
          "checked:bg-primary checked:border-primary",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring ring-offset-2 ring-offset-background"
        ]
      )
    end

    alias :html_label :label

    attr_reader :label, :id

    def view_template
      div(class: "isolate inline-flex items-center gap-2") do
        html_label(class: "inline-grid *:[grid-area:1/1] shrink-0 place-items-center") do
          input(**attrs)
          checkmark
        end

        if label.present? || block_given?
          render(Label.new(for: id)) { label || yield }
        end
      end
    end

    private

    def checkmark
      span(
        class: "size-4 text-zinc-50 dark:text-zinc-950 opacity-0 peer-checked:opacity-100 pointer-events-none"
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
