# frozen_string_literal: true

module NitroKit
  class FieldGroup < Component
    def initialize(
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      super(
        component: :field_group,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template(&block)
      raise ArgumentError, "field group requires a block" unless block

      div(**root_attributes, &block)
    end
  end
end
