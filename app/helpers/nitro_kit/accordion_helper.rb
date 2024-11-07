module NitroKit
  module AccordionHelper
    def nk_accordion(**attrs, &block)
      render(Accordion.new(**attrs), &block)
    end
  end
end 
