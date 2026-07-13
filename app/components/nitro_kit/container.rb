# frozen_string_literal: true

module NitroKit
  class Container < Component
    SIZES = %i[sm md lg xl].freeze

    def initialize(
      size:,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      size = validate_choice!(:size, size, SIZES)

      super(
        component: :container,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes) { yield if block_given? }
    end
  end
end
