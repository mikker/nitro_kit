module NitroKit
  class FieldGroup < Component
    FIELD_GROUP_BASE = "space-y-6"

    def view_template(&block)
      div(
        **attrs,
        class: merge([FIELD_GROUP_BASE, attrs[:class]]),
        &block
      )
    end
  end
end
