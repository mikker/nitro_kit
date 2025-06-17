# frozen_string_literal: true

module NitroKit
  module SwitchHelper
    def nk_switch(**attrs, &block)
      render(Switch.from_erb(**attrs), &block)
    end
  end
end
