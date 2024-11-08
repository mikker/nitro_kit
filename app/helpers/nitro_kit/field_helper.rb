module NitroKit
  module FieldHelper
    def nk_field(*args, **options, &block)
      render(NitroKit::Field.new(*args, **options, &block))
    end
  end
end
