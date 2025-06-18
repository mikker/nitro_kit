# frozen_string_literal: true

module NitroKit
  module ComboboxHelper
    def nk_combobox(name = nil, options = [], **attrs)
      render(NitroKit::Combobox.from_template(name:, options:, **attrs))
    end
  end
end
