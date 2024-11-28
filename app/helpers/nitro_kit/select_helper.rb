# frozen_string_literal: true

module NitroKit
  module SelectHelper
    def nk_select(options = nil, value: nil, **attrs, &block)
      render(Select.new(options, value:, **attrs), &block)
    end
  end
end
