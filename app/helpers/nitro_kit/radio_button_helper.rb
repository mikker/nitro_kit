# frozen_string_literal: true

module NitroKit
  module RadioButtonHelper
    def nk_radio_button(
      compat_object_name = nil,
      compat_method = nil,
      compat_tag_value = nil,
      compat_options = {},
      label: nil,
      **attrs
    )
      name = field_name(compat_object_name, compat_method)
      value = compat_tag_value || attrs[:value]

      render(RadioButton.from_template(label:, name:, value:, **attrs))
    end

    def nk_radio_button_group(**attrs, &block)
      render(RadioButtonGroup.from_template(**attrs), &block)
    end
  end
end
