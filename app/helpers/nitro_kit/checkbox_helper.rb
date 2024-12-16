# frozen_string_literal: true

module NitroKit
  module CheckboxHelper
    # Make API compatible with Rails' checkbox but allow empty arguments
    def nk_checkbox(
      compat_object_name = nil,
      compat_method = nil,
      compat_options = {},
      compat_checked_value = "1",
      compat_unchecked_value = "0",
      label: nil,
      **attrs
    )
      name = field_name(compat_object_name, compat_method)
      checked = compat_options["checked"] || attrs[:checked]

      # TODO: multiple, unchecked hidden field

      render(Checkbox.new(name:, label:, value: compat_checked_value, checked:, **attrs))
    end

    def nk_checkbox_group(**attrs, &block)
      render(CheckboxGroup.new(**attrs), &block)
    end
  end
end
