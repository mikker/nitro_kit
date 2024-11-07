module NitroKit
  class Label < Component
    def view_template
      label(
        **attrs,
        class: merge(["text-sm font-medium select-none", class_list])
      ) { yield }
    end
  end
end
