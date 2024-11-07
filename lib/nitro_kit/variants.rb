module NitroKit
  module Variants
    module ClassMethods
      def automatic_variants(variants, method_name)
        _, prefix, original = method_name.match(/(ik_)(.+)/).to_a

        variants.each do |variant, class_name|
          variant_method_name = "#{prefix}#{variant}_#{original}"

          define_method(variant_method_name) do |*args, **kwargs, &block|
            send(method_name, *args, variant:, **kwargs, &block)
          end
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
