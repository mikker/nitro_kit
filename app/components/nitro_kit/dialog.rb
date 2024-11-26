module NitroKit
  class Dialog < Component
    def initialize(identifier: nil, **attrs)
      @identifier = identifier || SecureRandom.hex(6)
    end

    attr_reader :identifier

    def view_template
      div(data: {controller: "nk--dialog", action: "click->nk--dialog#clickOutside"}) do
        yield
      end
    end

    def trigger(**attrs, &block)
      div(
        **attrs,
        data: data_merge(
          {nk__dialog_target: "trigger", action: "click->nk--dialog#open"},
          attrs[:data]
        ),
        &block
      )
    end

    alias :html_dialog :dialog

    def dialog(**attrs, &block)
      html_dialog(
        **attrs,
        class: merge([dialog_class, attrs[:class]]),
        data: data_merge(
          {nk__dialog_target: "dialog"},
          attrs[:data]
        ),
        aria: {
          labelledby: id(:title),
          describedby: id(:description)
        },
        &block
      )
    end

    def close_button(**attrs)
      render(
        Button.new(
          variant: :ghost,
          size: :sm,
          **attrs,
          class: merge("absolute top-2 right-2", attrs[:class]),
          data: data_merge(attrs[:data], action: "nk--dialog#close")
        )
      ) do
        render(Icon.new(name: "x"))
      end
    end

    def title(text = nil, **attrs)
      h2(id: id(:title), **attrs, class: merge("text-lg font-semibold mb-2", attrs[:class])) do
        text || (block_given? ? yield : "")
      end
    end

    def description(text = nil, **attrs)
      p(
        id: id(:description),
        **attrs,
        class: merge("text-muted-foreground mb-6 text-sm leading-relaxed", attrs[:class])
      ) do
        text || (block_given? ? yield : "")
      end
    end

    private

    def id(suffix = nil)
      "nk-#{identifier}#{suffix ? "-#{suffix}" : ""}"
    end

    def dialog_class
      [
        "border rounded-xl max-w-lg w-full bg-background text-foreground shadow-lg m-auto p-6",
        "dark:backdrop:bg-black/50"
      ]
    end
  end
end
