module NitroKit
  module SelectHelper
    def nk_select(options = [], value: nil, **attrs, &block)
      render(Select.new(options, value:, **attrs), &block)
    end
  end
end
