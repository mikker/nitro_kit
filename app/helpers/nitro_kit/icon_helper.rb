module NitroKit
  module IconHelper
    def ik_icon(name, **attrs)
      render(NitroKit::Icon.new(name: name, **attrs))
    end
  end
end
