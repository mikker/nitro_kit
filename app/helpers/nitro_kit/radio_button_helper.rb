# frozen_string_literal: true

module NitroKit
  module RadioButtonHelper
    def nk_radio_button(label: nil, **attrs)
      render(RadioButton.new(label:, **attrs))
    end

    def nk_radio_group(**attrs, &block)
      render(RadioGroup.new(**attrs), &block)
    end
  end
end
