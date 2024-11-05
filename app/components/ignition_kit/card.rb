module IgnitionKit
  class Card < Component
    def initialize(**attrs)
      @attrs = attrs
    end

    def view_template(&block)
      div(class: "rounded-lg border p-6 space-y-6 shadow-sm", &block)
    end
  end
end
