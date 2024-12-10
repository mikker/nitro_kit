# frozen_string_literal: true

module NitroKit
  module ButtonGroupHelper
    def nk_button_group(**attrs, &block)
      render(ButtonGroup.new(**attrs), &block)
    end
  end
end
