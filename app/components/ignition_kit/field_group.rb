module IgnitionKit
  class FieldGroup < Component
    FIELD_GROUP_BASE = "space-y-6"

    def initialize(**attrs)
      @attrs = attrs
      @class_list = merge([FIELD_GROUP_BASE, attrs[:class]])
    end

    def view_template(&block)
      div(**attrs, class: class_list, &block)
    end
  end
end
