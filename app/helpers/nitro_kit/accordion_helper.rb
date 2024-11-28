# frozen_string_literal: true

module NitroKit
  module AccordionHelper
    def nk_accordion(**attrs, &block)
      render(Accordion.new(**attrs), &block)
    end
  end
end
