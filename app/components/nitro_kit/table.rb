# frozen_string_literal: true

module NitroKit
  class Table < Component
    def initialize(**attrs)
      super(
        attrs,
        class: "w-full caption-bottom text-sm divide-y"
      )
    end

    def view_template
      div(class: "w-full overflow-x-scroll") do
        table(**attrs) do
          yield
        end
      end
    end

    alias :html_thead :thead
    alias :html_tbody :tbody
    alias :html_tr :tr
    alias :html_th :th
    alias :html_td :td

    builder_method def thead(**attrs)
      html_thead(**attrs) { yield }
    end

    builder_method def tbody(**attrs)
      html_tbody(**mattr(attrs, class: "[&_tr:last-child]:border-0")) { yield }
    end

    builder_method def tr(**attrs)
      html_tr(**mattr(attrs, class: "border-b")) { yield }
    end

    builder_method def th(text = nil, align: :left, **attrs, &block)
      html_th(**mattr(attrs, class: [header_cell_classes, cell_classes, align_classes(align), "font-medium"])) do
        text_or_block(text, &block)
      end
    end

    builder_method def td(text = nil, align: nil, **attrs, &block)
      html_td(**mattr(attrs, class: [cell_classes, align_classes(align)])) do
        text_or_block(text, &block)
      end
    end

    private

    def header_cell_classes
      ""
    end

    def cell_classes
      "whitespace-nowrap py-2 min-h-10 px-2"
    end

    def align_classes(align = nil)
      case align
      when :left
        "text-left"
      when :center
        "text-center"
      when :right
        "text-right"
      else
        nil
      end
    end
  end
end
