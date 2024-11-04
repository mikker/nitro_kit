module IgnitionKit
  module CardHelper
    def ik_card(**attrs, &block)
      render(Card.new(**attrs), &block)
    end
  end
end
