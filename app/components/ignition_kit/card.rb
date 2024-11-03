module IgnitionKit
  class Card < Component
    BASE = "rounded-lg border p-6 space-y-6 shadow-sm".freeze

    def initialize(**attrs)
      @attrs = attrs
    end

    def view_template(&block)
      div(class: BASE, &block)
    end
  end
end
