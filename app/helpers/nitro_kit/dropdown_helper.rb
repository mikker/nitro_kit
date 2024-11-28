# frozen_string_literal: true

module NitroKit
  module DropdownHelper
    def nk_dropdown(**attrs, &block)
      render(NitroKit::Dropdown.new(**attrs), &block)
    end
  end
end
