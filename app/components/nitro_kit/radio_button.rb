# frozen_string_literal: true

module NitroKit
  class RadioButton < Component
    include ActionView::Helpers::FormTagHelper

    def initialize(name: nil, value: nil, label: nil, **attrs)
      super(**attrs)

      @name = name
      @value = value
      @label_text = label
      @id = id || SecureRandom.hex(4)
    end

    attr_reader(
      :name,
      :value,
      :id,
      :label_text
    )

    def view_template
      div(class: merge("inline-flex items-center gap-2", attrs[:class])) do
        label(class: "inline-grid *:[grid-area:1/1] place-items-center") do
          input(
            **attrs,
            type: "radio",
            name:,
            value:,
            id:,
            class: merge(
              "peer appearance-none size-5 shadow-sm rounded-full border text-foreground bg-background",
              "[&[aria-checked='true']]:bg-primary",
              "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            )
          )
          dot
        end

        if label_text.present?
          render(Label.new(for: id)) { label_text }
        end
      end
    end

    private

    def dot
      svg(
        class: class_names(
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
