# frozen_string_literal: true

module NitroKit
  module TableHelper
    def nk_table(**attrs, &block)
      render(Table.new(**attrs), &block)
    end
  end
end
