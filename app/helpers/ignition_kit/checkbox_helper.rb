module IgnitionKit
  module CheckboxHelper
    CONTAINER_BASE = "relative inline-flex items-center"

    INPUT_BASE = [
      "peer appearance-none shadow size-5 rounded border-zinc-400 text-foreground",
      "checked:bg-primary checked:border-primary checked:text-white",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    ].freeze

    SPAN_BASE = "absolute text-white opacity-0 peer-checked:opacity-100 top-1/2 left-1/2 transform -translate-x-1/2 transition-transform -translate-y-2/3 opacity-0 peer-checked:opacity-100 duration-100 ease-out peer-checked:-translate-y-1/2 pointer-events-none"

    SVG = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor" stroke="currentColor" stroke-width="1">
        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
      </svg>
    SVG
      .html_safe
      .freeze

    def ik_checkbox(name = nil, value = "1", label: nil, **attrs)
      class_list = merge([INPUT_BASE, attrs.delete(:class)])

      attrs[:name] ||= name
      attrs[:value] ||= value

      tag.label(class: CONTAINER_BASE) do
        concat(tag.input(**attrs, type: "checkbox", class: class_list))
        concat(tag.span(SVG, class: SPAN_BASE))
        concat(tag.label(label, class: "ml-2")) if label
      end
    end
  end
end
