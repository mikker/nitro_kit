module NitroKit
  module CardHelper
    def nk_card(**attrs, &block)
      render(Card.new(**attrs), &block)
    end
  end
end