module IgnitionKit
  module ButtonGroupHelper
    def ik_button_group(**attrs, &block)
      render(ButtonGroup.new(**attrs), &block)
    end
  end
end
