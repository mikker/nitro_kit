# frozen_string_literal: true

module NitroKit
  module TabsHelper
    def nk_tabs(**attrs, &block)
      render(Tabs.new(**attrs), &block)
    end
  end
end
