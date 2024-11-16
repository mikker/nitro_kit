module NitroKit
  class Table < Component
    def view_template
      div(class: "relative w-full overflow-auto") do
        table(class: merge("w-full caption-bottom text-sm divide-y", attrs[:class])) do
          yield
        end
      end
    end

    alias :original_thead :thead

    def thead(**attrs)
      original_thead(**attrs) { yield }
    end

    alias :original_tbody :tbody

    def tbody(**attrs)
      original_tbody(**attrs, class: merge("[&_tr:last-child]:border-0", attrs[:class])) { yield }
    end

    alias :original_tr :tr

    def tr(**attrs)
      original_tr(**attrs, class: merge("border-b", attrs[:class])) { yield }
    end

    alias :original_th :th

    def th(**attrs)
      original_th(**attrs, class: merge(cell_classes, "font-medium text-left", attrs[:class])) { yield }
    end

    alias :original_td :td

    def td(**attrs)
      original_td(**attrs, class: merge(cell_classes, attrs[:class])) { yield }
    end

    private

    def cell_classes
      "py-3 px-3 first:pl-0 last:pr-0"
    end
  end
end
