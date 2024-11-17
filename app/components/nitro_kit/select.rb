module NitroKit
  class Select < Component
    def initialize(options = nil, value: nil, **attrs)
      @options = options
      @value = value

      super(**attrs)
    end

    attr_reader :value, :options

    def view_template
      span(
        data: { slot: "control" },
        class: merge(wrapper_class, attrs[:class])
      ) do
        select(**attrs, class: merge(select_class)) do
          options ? options.map { |o| option(*o) } : yield
        end
        chevron_icon
      end
    end

    alias :html_option :option

    def option(key = nil, value = nil, **attrs, &block)
      value ||= key
      attrs[:selected] = attrs[:value] == value
      html_option(**attrs) { key || yield }
    end

    private

    def wrapper_class
      "isolate relative group/select"
    end

    def select_class
      [
        "appearance-none bg-background text-foreground rounded-md border px-3 py-2 pr-10 w-full",
        # Focus
        "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
      ]
    end

    def chevron_icon
      span(
        class: merge(
          "absolute top-1/2 -translate-y-1/2 right-1.5 w-[1.25em]",
          "text-muted-foreground pointer-events-none",
          "group-hover/select:text-foreground"
        )
      ) do
        svg(
          class: "size-full",
          viewbox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: 1
        ) do |svg|
          svg.path(d: "m7 15 5 5 5-5")
          svg.path(d: "m7 9 5-5 5 5")
        end
      end
    end
  end
end
