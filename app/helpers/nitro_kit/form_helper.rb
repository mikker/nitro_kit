# frozen_string_literal: true

module NitroKit
  module FormHelper
    def nk_form_with(**attrs, &block)
      form_with(**attrs, builder: NitroKit::FormBuilder, &block)
    end

    def nk_form_for(*args, **attrs, &block)
      form_for(*args, **attrs, builder: NitroKit::FormBuilder, &block)
    end
  end
end
