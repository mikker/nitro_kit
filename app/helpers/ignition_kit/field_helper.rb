module IgnitionKit
  module FieldHelper
    def field(attribute, **options)
      render(IgnitionKit::Field.new(attribute, **options))
    end
  end
end
