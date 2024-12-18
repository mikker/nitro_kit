# frozen_string_literal: true

module NitroKit
  module SelectHelper
    def nk_select(
      compat_object_name = nil,
      compat_method = nil,
      options = nil,
      compat_options = {},
      value: nil,
      include_blank: false,
      prompt: nil,
      index: nil,
      **attrs,
      &block
    )
      name = field_name(compat_object_name, compat_method)

      # TODO: support index

      render(Select.new(options, value:, include_blank:, prompt:, **compat_options, **attrs), &block)
    end
  end
end
