module NitroKit
  module DialogHelper
    def nk_dialog(**attrs, &block)
      render(Dialog.new(**attrs), &block)
    end
  end
end