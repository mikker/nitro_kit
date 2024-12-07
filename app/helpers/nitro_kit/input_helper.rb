# frozen_string_literal: true

module NitroKit
  module InputHelper
    def nk_input(**attrs)
      render(Input.new(**attrs))
    end
  end
end
