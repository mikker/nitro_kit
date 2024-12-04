module NitroKit
  module AlertHelper
    include Variants

    def nk_alert(**attrs, &block)
      render(Alert.new(**attrs), &block)
    end

    automatic_variants(Alert::VARIANTS, :nk_alert)
  end
end
