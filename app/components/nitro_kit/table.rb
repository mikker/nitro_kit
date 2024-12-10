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

    def thead(**attrs)
      html_thead(**attrs) { yield }
    end

    def tbody(**attrs)
      html_tbody(**mattr(attrs, class: "[&_tr:last-child]:border-0")) { yield }
    end

    def tr(**attrs)
      html_tr(**mattr(attrs, class: "border-b")) { yield }
    end

    def th(**attrs)
      html_th(**mattr(attrs, class: [cell_classes, "font-medium text-left"])) { yield }
    end

    def td(**attrs)
      html_td(**mattr(attrs, class: cell_classes)) { yield }
    end

    private

    def cell_classes
      "py-3 px-3 first:pl-0 last:pr-0"
    end
  end
end
