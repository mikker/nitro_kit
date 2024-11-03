module IgnitionKit
  module ButtonGroupHelper
    def button_group(**attrs, &block)
      render(ButtonGroup.new(**attrs), &block)
    end
  end
end
