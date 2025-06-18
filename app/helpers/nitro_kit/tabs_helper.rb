# frozen_string_literal: true

module NitroKit
  module TabsHelper
    def nk_tabs(**attrs, &block)
      render(Tabs.from_template(**attrs), &block)
    end
  end
end
