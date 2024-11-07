module NitroKit
  module DropdownHelper
    def ik_dropdown(**attrs, &block)
      render(NitroKit::Dropdown.new(**attrs), &block)
    end
  end
end
