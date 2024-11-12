module NitroKit
  class FieldGroup < Component
    FIELD_GROUP = "flex flex-col items-start gap-4"

    def view_template(&block)
      div(**attrs, class: merge(FIELD_GROUP, attrs[:class]), &block)
    end
  end
end
