# frozen_string_literal: true

module NitroKit
  class HStack < Component
    GAPS = LayoutOptions::GAPS
    ALIGNMENTS = %i[start center stretch].freeze
    JUSTIFICATIONS = %i[start end between].freeze

    def initialize(
      gap: :md,
      align: :center,
      justify: :start,
      wrap: false,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      gap = validate_choice!(:gap, gap, GAPS)
      align = validate_choice!(:align, align, ALIGNMENTS)
      justify = validate_choice!(:justify, justify, JUSTIFICATIONS)
      wrap = validate_boolean!(:wrap, wrap)

      super(
        component: :h_stack,
        attributes: { id:, data: { gap:, align:, justify:, wrap: wrap.to_s } }.compact,
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
