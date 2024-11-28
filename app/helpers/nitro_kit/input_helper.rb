# frozen_string_literal: true

module NitroKit
  module InputHelper
    def nk_input(name = nil, value = nil, **attrs)
      render(Input.new({name:, value:, **attrs}))
    end
  end
end
