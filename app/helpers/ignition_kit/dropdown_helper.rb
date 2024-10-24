module IgnitionKit
  module DropdownHelper
    def dropdown(**attrs, &block)
      render(IgnitionKit::Dropdown.new(**attrs), &block)
    end
  end
end
