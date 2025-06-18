# frozen_string_literal: true

module NitroKit
  module SwitchHelper
    def nk_switch(**attrs, &block)
      render(Switch.from_template(**attrs), &block)
    end
  end
end
