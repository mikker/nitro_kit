# frozen_string_literal: true

module NitroKit
  module FieldHelper
    def nk_field(*args, **attrs, &block)
      render(NitroKit::Field.new(*args, **attrs), &block)
    end

    def nk_field_group(**attrs)
      render(NitroKit::FieldGroup.new(**attrs)) { yield }
    end

    def nk_fieldset(**attrs, &block)
      render(NitroKit::Fieldset.new(**attrs), &block)
    end
  end
end
