module IgnitionKit
  module FieldHelper
    def ik_field(attribute, **options)
      render(IgnitionKit::Field.new(attribute, **options))
    end
  end
end
