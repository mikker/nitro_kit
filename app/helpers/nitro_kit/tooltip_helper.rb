# frozen_string_literal: true

module NitroKit
  module TooltipHelper
    def nk_tooltip(**attrs, &block)
      render(Tooltip.from_erb(**attrs), &block)
    end
  end
end
