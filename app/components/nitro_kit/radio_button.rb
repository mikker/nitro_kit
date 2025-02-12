# frozen_string_literal: true

module NitroKit
  class RadioButton < Component
    def initialize(label: nil, **attrs)
      @label = label
      @id = id || SecureRandom.hex(4)

      @class = attrs.delete(:class)

      super(
        attrs,
        type: "radio",
        id: @id,
        class: [
          "peer appearance-none size-5 shadow-sm rounded-full border text-foreground bg-background",
          "[&[aria-checked='true']]:bg-primary",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        ]
      )
    end

    alias :html_label :label

    attr_reader(
      :id,
      :label
    )

    def view_template
      div(class: merge_class("inline-flex items-center gap-2", @class)) do
        html_label(class: "inline-grid *:[grid-area:1/1] place-items-center") do
          input(**attrs)
          dot
        end

        if label.present? || block_given?
          render(Label.new(for: id)) do
            label || (block_given? ? yield : nil)
          end
        end
      end
    end

    private

    def dot
      svg(
        class: merge_class(
          "row-start-1 col-start-1",
          "size-2.5 text-primay opacity-0 pointer-events-none",
          "peer-checked:opacity-100"
        ),
        viewbox: "0 0 20 20",
        fill: "currentColor",
        stroke: "none"
      ) do |svg|
        svg.circle(cx: 10, cy: 10, r: 10)
      end
    end
  end
end
