module NitroKit
  module FieldHelper
    def ik_field(attribute, **options)
      render(NitroKit::Field.new(attribute, **options))
    end
  end
end
