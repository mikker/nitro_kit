# frozen_string_literal: true

module NitroKit
  module DialogHelper
    def nk_dialog(**attrs, &block)
      render(Dialog.from_template(**attrs), &block)
    end
  end
end
