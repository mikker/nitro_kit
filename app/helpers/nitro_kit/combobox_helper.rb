# frozen_string_literal: true

module NitroKit
  module ComboboxHelper
    def nk_combobox(name = nil, options = [], **attrs)
      render(NitroKit::Combobox.from_erb(name:, options:, **attrs))
    end
  end
end
