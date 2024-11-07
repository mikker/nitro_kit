module NitroKit
  module SwitchHelper
    def nk_switch(
      name,
      checked: false,
      disabled: false,
      size: :base,
      description: nil,
      **attrs,
      &block
    )
      render(NitroKit::Switch.new(name, checked:, disabled:, size:, description:, **attrs), &block)
    end
  end
end
