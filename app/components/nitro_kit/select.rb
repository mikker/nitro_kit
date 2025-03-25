# frozen_string_literal: true

module NitroKit
  class Select < Component
    def initialize(options = nil, value: nil, include_empty: false, prompt: nil, index: nil, **attrs)
      @options = options
      @value = value.to_s
      @include_empty = include_empty
      @prompt = prompt
      @index = index

      super(
        attrs,
        class: wrapper_class
      )
    end

    attr_reader :value, :options, :include_empty, :prompts, :index

    def view_template
      span(class: wrapper_class, data: {slot: "control"}) do
        select(**attrs, class: select_class) do
          option if include_empty
          options ? options.map { |o| option(*o) } : yield
        end

        chevron_icon
      end
    end

    alias :html_option :option

    builder_method def option(key_or_value = nil, value = nil, **attrs, &block)
      value ||= key_or_value

      html_option(value:, selected: @value == value.to_s, **attrs) do
        if block_given?
          yield
        else
          key_or_value
        end
      end
    end

    private

    def wrapper_class
      "w-fit inline-grid *:[grid-area:1/1] group/select"
    end

    def select_class
      [
        "appearance-none bg-background text-foreground rounded-md border px-3 py-2 pr-10 w-full",
        # Focus
        "focus:outline-none ring-ring ring-offset-2 ring-offset-background focus-visible:ring-2"
      ]
    end

    def chevron_icon
      svg(
        class: "size-4 self-center place-self-end mr-1.5 text-muted-content pointer-events-none group-hover/select:text-foreground",
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
