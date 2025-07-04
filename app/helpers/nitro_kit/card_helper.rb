# frozen_string_literal: true

module NitroKit
  module CardHelper
    def nk_card(**attrs, &block)
      render(Card.from_template(**attrs), &block)
    end
  end
end
