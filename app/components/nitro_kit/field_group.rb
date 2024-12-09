# frozen_string_literal: true

module NitroKit
  class FieldGroup < Component
    def view_template(&block)
      div(**attrs, class: merge_class(base_class, attrs[:class]), &block)
    end

    private

    def base_class
      "flex flex-col items-stretch gap-4"
    end
  end
end
