module NitroKit
  module CheckboxHelper
    def nk_checkbox(label: nil, **attrs)
      render(NitroKit::Checkbox.new(label:, **attrs))
    end
  end
end
