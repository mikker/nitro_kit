# frozen_string_literal: true

module NitroKit
  class Flex < Component
    GAPS = LayoutOptions::GAPS
    DIRECTIONS = %i[row col row_reverse col_reverse].freeze
    ALIGNMENTS = %i[start center end stretch baseline].freeze
    JUSTIFICATIONS = %i[start center end between around evenly].freeze
    WRAPS = %i[nowrap wrap wrap_reverse].freeze

    def initialize(
      dir:,
      gap: 4,
      align: :start,
      justify: :start,
      wrap: :nowrap,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      dir = responsive_value(:dir, dir, DIRECTIONS)
      gap = responsive_value(:gap, gap, GAPS)
      align = responsive_value(:align, align, ALIGNMENTS)
      justify = responsive_value(:justify, justify, JUSTIFICATIONS)
      wrap = responsive_value(:wrap, wrap, WRAPS)

      super(
        component: :flex,
        attributes: { id:, data: { dir:, gap:, align:, justify:, wrap: } }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes) { yield if block_given? }
    end

    private

    def responsive_value(property, value, allowed)
      ResponsiveValue.new(property:, value:, allowed:).to_s
    end
  end
end
