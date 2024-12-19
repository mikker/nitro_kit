# frozen_string_literal: true

module NitroKit
  module FieldHelper
    def nk_field(*args, **attrs, &block)
      render(NitroKit::Field.new(*args, **attrs), &block)
    end
  end
end
