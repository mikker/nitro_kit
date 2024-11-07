module NitroKit
  module IconHelper
    def nk_icon(name, **attrs)
      render(NitroKit::Icon.new(name: name, **attrs))
    end
  end
end
