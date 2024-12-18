# frozen_string_literal: true

module NitroKit
  class Toast < Component
    def initialize(**attrs)
      super(
        attrs,
        role: "region",
        tabindex: "-1",
        aria: {label: "Notifications"},
        class: "pointer-events-none"
      )
    end

    def view_template
      div(**attrs) do
        ol(class: list_class, data: {nk__toast_target: "list"})
      end

      template(data: {nk__toast_target: "template"}) do
        item
      end
    end

    def item(title: nil, description: nil, **attrs, &block)
      li(
        **mattr(
          attrs,
          role: "status",
          aria: {live: "off", atomic: "true"},
          tabindex: "0",
          data: {state: "closed"},
          class: item_class
        )
      ) do
        div(class: "grid gap-1") do
          div(class: "text-sm font-semibold", data: {slot: "title"}) do
            title && plain(title)
          end

          div(class: "text-sm opacity-90", data: {slot: "description"}) do
            text_or_block(description, &block)
          end
        end
      end
    end

    private

    def list_class
      "fixed z-[100] flex max-h-screen w-full p-5 bottom-0 right-0 flex-col h-0 md:max-w-[420px]"
    end

    def item_class
      "shrink-0 pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md p-6 pr-8 shadow-lg transition-all border bg-background text-foreground opacity-0 transition-all data-[state=open]:opacity-100 data-[state=open]:-translate-y-full"
    end
  end
end
