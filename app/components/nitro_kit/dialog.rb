module NitroKit
  class Dialog < Component
    def view_template
      div(data: {controller: "nk--dialog"}) do
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

    def content(**attrs, &block)
      dialog(
        **attrs,
        class: merge([dialog_class, attrs[:class]]),
        data: data_merge(
          {nk__dialog_target: "content"},
          attrs[:data]
        ),
        &block
      )
    end

    private

    def dialog_class
      "border rounded-xl max-w-xl w-full bg-background text-foreground shadow-lg m-auto p-5"
    end
  end
end
