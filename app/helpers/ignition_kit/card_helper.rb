module IgnitionKit
  module CardHelper
    def card(**attrs, &block)
      render(Card.new(**attrs), &block)
    end
  end
end
