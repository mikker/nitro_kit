module IgnitionKit
  module ToggleHelper
    def toggle(
      name,
      checked: false,
      disabled: false,
      size: :base,
      description: nil,
      **attrs,
      &block
    )
      render(IgnitionKit::Toggle.new(name, checked:, disabled:, size:, description:, **attrs), &block)
    end
  end
end
