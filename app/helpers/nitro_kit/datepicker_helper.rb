# frozen_string_literal: true

module NitroKit
  module DatepickerHelper
    def nk_datepicker(**attrs, &block)
      render(Datepicker.new(**attrs), &block)
    end
  end
end
