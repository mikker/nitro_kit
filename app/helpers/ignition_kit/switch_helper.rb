module IgnitionKit
  module SwitchHelper
    def ik_switch(
      name,
      checked: false,
      disabled: false,
      size: :base,
      description: nil,
      **attrs,
      &block
    )
      render(IgnitionKit::Switch.new(name, checked:, disabled:, size:, description:, **attrs), &block)
    end
  end
end
