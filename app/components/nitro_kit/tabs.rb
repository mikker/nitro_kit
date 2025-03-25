# frozen_string_literal: true

module NitroKit
  class Tabs < Component
    def initialize(default: nil, **attrs)
      @default = default
      @id = attrs[:id] || SecureRandom.hex(6)

      super(
        attrs,
        data: {controller: "nk--tabs", nk__tabs_active_value: default},
        class: base_class
      )
    end

    attr_reader :default, :id

    def view_template
      div(**attrs) do
        yield
      end
    end

    builder_method def tabs(**attrs)
      div(**mattr, role: "tabtabs", class: tabs_class) do
        yield
      end
    end

    builder_method def tab(key, text = nil, **attrs, &block)
      button(
        **mattr(
          attrs,
          aria: {
            selected: (default == key).to_s,
            controls: tab_id(key, :panel)
          },
          class: tab_class,
          data: {
            action: "nk--tabs#setActiveTab keydown.left->nk--tabs#prevTab keydown.right->nk--tabs#nextTab",
            key:,
            nk__tabs_key_param: key,
            nk__tabs_target: "tab"
          },
          id: tab_id(key, :tab),
          role: "tab",
          tabindex: default == key ? 0 : -1
        )
      ) do
        text_or_block(text, &block)
      end
    end

    builder_method def panel(key, **attrs)
      div(
        **mattr(
          attrs,
          aria: {
            hidden: (default != key).to_s,
            labelledby: tab_id(key, :tab)
          },
          class: panel_class,
          data: {
            key:,
            nk__tabs_target: "panel"
          },
          id: tab_id(key, :panel),
          name: key,
          role: "tabpanel"
        )
      ) do
        yield
      end
    end

    private

    def tab_id(key, suffix)
      "#{id}-#{key}-#{suffix}"
    end

    def base_class
      "w-full"
    end

    def tabs_class
      "flex gap-4 border-b h-10"
    end

    def tab_class
      "border-b-2 border-transparent hover:border-primary focus-visible:border-primary cursor-pointer text-muted-content aria-[selected=true]:text-foreground font-medium aria-[selected=true]:border-primary -mb-px px-2"
    end

    def panel_class
      "aria-[hidden=true]:hidden py-4"
    end
  end
end
