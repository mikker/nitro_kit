module NitroKit
  module FieldHelper
    def nk_field(attribute, **options)
      render(NitroKit::Field.new(attribute, **options))
    end
  end
end
