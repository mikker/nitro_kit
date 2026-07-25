# frozen_string_literal: true

module NitroKit
  class Typeset < Component
    def initialize(
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      super(
        component: :typeset,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template(&content)
      raise ArgumentError, "Typeset requires a content block" unless content

      div(**root_attributes, &content)
    end
  end
end
