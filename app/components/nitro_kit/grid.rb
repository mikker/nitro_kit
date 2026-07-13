# frozen_string_literal: true

module NitroKit
  class Grid < Component
    COLUMNS = [ 3 ].freeze

    def initialize(
      cols:,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      cols = validate_choice!(:cols, cols, COLUMNS)

      super(
        component: :grid,
        attributes: { id:, data: { cols: } }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes) { yield if block_given? }
    end
  end
end
