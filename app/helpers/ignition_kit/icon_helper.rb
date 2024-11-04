module IgnitionKit
  module IconHelper
    def ik_icon(name, **attrs)
      render(IgnitionKit::Icon.new(name: name, **attrs))
    end
  end
end
