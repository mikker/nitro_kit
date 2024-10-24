module IgnitionKit
  module IconHelper
    def icon(name, **attrs)
      render(IgnitionKit::Icon.new(name: name, **attrs))
    end
  end
end
