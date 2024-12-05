# frozen_string_literal: true

module NitroKit
  module ComboboxHelper
    def nk_combobox(name = nil, options = [], **attrs)
      render(NitroKit::Combobox.new(name:, options:, **attrs))
    end
  end
end
