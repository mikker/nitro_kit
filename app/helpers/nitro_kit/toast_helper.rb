# frozen_string_literal: true

module NitroKit
  module ToastHelper
    def nk_toast(**attrs, &block)
      render(Toast.new(**attrs), &block)
    end
  end
end
