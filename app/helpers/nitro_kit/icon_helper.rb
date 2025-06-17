# frozen_string_literal: true

module NitroKit
  module IconHelper
    def nk_icon(name, **attrs)
      render(NitroKit::Icon.from_erb(name, **attrs))
    end
  end
end
