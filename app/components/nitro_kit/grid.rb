# frozen_string_literal: true

module NitroKit
  class Grid < Component
    COLUMNS = (1..12).to_a.freeze
    GAPS = LayoutOptions::GAPS

    def initialize(
      cols:,
      gap: 4,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      cols = ResponsiveValue.new(property: :cols, value: cols, allowed: COLUMNS).to_s
      gap = ResponsiveValue.new(property: :gap, value: gap, allowed: GAPS).to_s

      super(
        component: :grid,
        attributes: { id:, data: { cols:, gap: } }.compact,
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
