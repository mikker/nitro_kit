# frozen_string_literal: true

module NitroKit
  class Table < Component
    def initialize(wrapper: {}, **attrs)
      super(attrs)
      @wrapper = wrapper
    end

    attr_reader :wrapper

    def view_template
      div(**mattr(wrapper, class: "w-full overflow-x-scroll")) do
        table(
          **mattr(
            attrs,
            class: "w-full caption-bottom text-sm divide-y"
          )
        ) do
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
      builder do
        html_thead(**attrs) { yield }
      end
    end

    def tbody(**attrs)
      builder do
        html_tbody(**mattr(attrs, class: "[&_tr:last-child]:border-0")) { yield }
      end
    end

    def tr(**attrs)
      builder do
        html_tr(**mattr(attrs, class: "border-b")) { yield }
      end
    end

    def th(text = nil, align: :left, **attrs, &block)
      builder do
        html_th(**mattr(attrs, class: [header_cell_classes, cell_classes, align_classes(align), "font-medium"])) do
          text_or_block(text, &block)
        end
      end
    end

    def td(text = nil, align: nil, **attrs, &block)
      builder do
        html_td(**mattr(attrs, class: [cell_classes, align_classes(align)])) do
          text_or_block(text, &block)
        end
      end
    end

    private

    def header_cell_classes
      ""
    end

    def cell_classes
      "py-2 min-h-10 px-2"
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
