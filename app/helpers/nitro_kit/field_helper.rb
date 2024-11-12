module NitroKit
  module FieldHelper
    def nk_field(*args, **options, &block)
      render(NitroKit::Field.new(*args, **options, &block))
    end

    def nk_field_group(**options)
      render(NitroKit::FieldGroup.new(**options)) { yield }
    end
  end
end
