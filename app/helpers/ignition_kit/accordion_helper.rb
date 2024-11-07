module IgnitionKit
  module AccordionHelper
    def ik_accordion(**attrs, &block)
      render(Accordion.new(**attrs), &block)
    end
  end
end 