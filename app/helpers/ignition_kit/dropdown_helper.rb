module IgnitionKit
  module DropdownHelper
    def ik_dropdown(**attrs, &block)
      render(IgnitionKit::Dropdown.new(**attrs), &block)
    end
  end
end
