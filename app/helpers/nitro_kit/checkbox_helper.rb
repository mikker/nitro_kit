module NitroKit
  module CheckboxHelper
    def nk_checkbox(label: nil, **attrs)
      render(Checkbox.new(label:, **attrs))
    end

    def nk_checkbox_group(**attrs, &block)
      render(CheckboxGroup.new(**attrs, &block))
    end
  end
end
