# frozen_string_literal: true

module NitroKit
  module DropdownHelper
    def nk_dropdown(**attrs, &block)
      render(Dropdown.from_template(**attrs), &block)
    end
  end
end
