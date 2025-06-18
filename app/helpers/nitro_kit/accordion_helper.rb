# frozen_string_literal: true

module NitroKit
  module AccordionHelper
    def nk_accordion(**attrs, &block)
      render(Accordion.from_template(**attrs), &block)
    end
  end
end
