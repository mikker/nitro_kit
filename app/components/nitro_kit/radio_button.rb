# frozen_string_literal: true

module NitroKit
  class RadioButton < Component
    def initialize(label: nil, id: nil, wrapper: {}, size: :md, **attrs)
      @label = label
      @id = id || "nk--" + SecureRandom.hex(4)
      @size = size
      @wrapper = wrapper

      super(
        attrs,
        id: @id,
        type: "radio",
        class: input_class
      )
    end

    alias :html_label :label

    attr_reader :id, :label, :size, :wrapper

    def view_template
      div(**mattr(wrapper, class: wrapper_class)) do
        html_label(class: merge_class("inline-grid *:[grid-area:1/1] shrink-0 place-items-center", size_class)) do
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
          "text-primary opacity-0 pointer-events-none",
          "peer-checked:opacity-100"
        ),
        viewbox: "0 0 20 20",
        fill: "currentColor",
        stroke: "none"
      ) do |svg|
        svg.circle(cx: 10, cy: 10, r: 10)
      end
    end

    def wrapper_class
      "inline-flex items-center gap-2"
    end

    def input_class
      [
        "peer appearance-none shadow-sm rounded-full border text-foreground bg-background",
        "[&[aria-checked='true']]:bg-primary",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      ]
    end

    def size_class
      case size
      when :md
        "[&>input]:size-5 [&>svg]:size-2.5"
      when :lg
        "[&>input]:size-7 [&>svg]:size-[calc(var(--spacing)*3+1px)]"
      else
        raise ArgumentError, "Unknown size `#{size}'"
      end
    end
  end
end
