# frozen_string_literal: true

module NitroKit
  class VStack < Component
    GAPS = LayoutOptions::GAPS
    ALIGNMENTS = %i[start center stretch].freeze

    def initialize(
      gap: :md,
      align: :start,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      gap = validate_choice!(:gap, gap, GAPS)
      align = validate_choice!(:align, align, ALIGNMENTS)

      super(
        component: :v_stack,
        attributes: { id:, data: { gap:, align: } }.compact,
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
