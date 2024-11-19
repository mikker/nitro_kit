module NitroKit
  module FormHelper
    def nk_form_with(**attrs, &block)
      form_with(**attrs, builder: NitroKit::FormBuilder, &block)
    end

    def nk_form_for(**attrs, &block)
      form_for(**attrs, builder: NitroKit::FormBuilder, &block)
    end
  end
end
