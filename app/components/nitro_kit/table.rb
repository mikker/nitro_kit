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
      div(class: "relative w-full overflow-auto") do
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

    builder_method def th(text = nil, **attrs, &block)
      html_th(**mattr(attrs, class: [cell_classes, "font-medium text-left"])) do
        text_or_block(text, &block)
      end
    end

    builder_method def td(text = nil, **attrs, &block)
      html_td(**mattr(attrs, class: cell_classes)) do
        text_or_block(text, &block)
      end
    end

    private

    def cell_classes
      "py-3 px-2"
    end
  end
end
