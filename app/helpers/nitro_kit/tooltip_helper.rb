# frozen_string_literal: true

module NitroKit
  module TooltipHelper
    def nk_tooltip(**attrs, &block)
      render(Tooltip.from_template(**attrs), &block)
    end
  end
end
