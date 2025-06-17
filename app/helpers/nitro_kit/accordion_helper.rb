# frozen_string_literal: true

module NitroKit
  module AccordionHelper
    def nk_accordion(**attrs, &block)
      render(Accordion.from_erb(**attrs), &block)
    end
  end
end
