# frozen_string_literal: true

module NitroKit
  module DatepickerHelper
    def nk_datepicker(**attrs, &block)
      render(Datepicker.from_template(**attrs), &block)
    end
  end
end
