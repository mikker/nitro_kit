module IgnitionKit
  class RadioButton < Component
    include ActionView::Helpers::FormTagHelper

    def initialize(name, value:, label: nil, **attrs)
      super(**attrs)

      @name = name
      @value = value
      @label_text = label
      @id = "#{sanitize_to_id(name)}_#{sanitize_to_id(value)}"
    end

    attr_reader(
      :name,
      :value,
      :id,
      :label_text
    )

    def view_template
      div(class: merge(["inline-flex items-center gap-2", class_list])) do
        label(class: "grid grid-cols-1 place-items-center shrink-0") do
          input(
            **attrs,
            type: "radio",
            name:,
            value:,
            id:,
            class: class_names(
              "peer row-start-1 col-start-1",
              "appearance-none size-5 shadow rounded-full border-zinc-400 text-foreground",
              "checked:bg-primary checked:border-primary checked:text-zinc-50 dark:checked:text-zinc-900",
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
          "size-3 text-zinc-50 dark:text-zinc-900 opacity-0 peer-checked:opacity-100 pointer-events-none",
          "row-start-1 col-start-1"
        ),
        viewbox: "0 0 20 20",
        fill: "currentColor",
        stroke: "currentColor",
        stroke_width: 0
      ) do |svg|
        svg.circle(cx: 10, cy: 10, r: 10)
      end
    end
  end
end
