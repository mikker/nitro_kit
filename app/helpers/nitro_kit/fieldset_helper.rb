# frozen_string_literal: true

module NitroKit
  module FieldsetHelper
    def nk_fieldset(**attrs, &block)
      render(NitroKit::Fieldset.from_template(**attrs), &block)
    end
  end
end
