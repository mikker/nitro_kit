module IgnitionKit
  class Card < Component
    def initialize(**attrs)
      @attrs = attrs
    end

    def view_template(&block)
      div(class: "rounded-lg border p-6 space-y-6 shadow-sm", &block)
    end

    def title(**attrs)
      h2(**attrs, class: merge(["text-lg font-bold", attrs[:class]])) { yield }
    end

    def body(**attrs)
      div(**attrs) { yield }
    end

    def footer(**attrs)
      div(**attrs, class: merge(["flex gap-2", attrs[:class]])) { yield }
    end
  end
end
