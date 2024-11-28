module NitroKit
  class Tabs < Component
    def initialize(default: nil, **attrs)
      @default = default
      @id = attrs[:id] || SecureRandom.hex(6)

      super(**attrs)
    end

    attr_reader :default, :id

    def view_template
      div(
        **attrs,
        data: data_merge(attrs[:data], {controller: "nk--tabs", nk__tabs_active_value: default}),
        class: merge(base_class, attrs[:class])
      ) do
        yield
      end
    end

    def tabs(**attrs)
      div(
        **attrs,
        role: "tabtabs",
        class: merge(tabs_class, attrs[:class])
      ) { yield }
    end

    def tab(key, **attrs)
      @default ||= key

      button(
        id: tab_id(key, :tab),
        **attrs,
        role: "tab",
        aria: {
          selected: (default == key).to_s,
          controls: tab_id(key, :panel)
        },
        data: data_merge(
          {
            nk__tabs_target: "tab",
            action: "nk--tabs#setActiveTab keydown.left->nk--tabs#prevTab keydown.right->nk--tabs#nextTab",
            nk__tabs_key_param: key,
            key:
          },
          attrs[:data]
        ),
        tabindex: default == key ? 0 : -1,
        class: merge(tab_class, attrs[:class])
      ) { block_given? ? yield : key }
    end

    def panel(key, **attrs)
      div(
        id: tab_id(key, :panel),
        **attrs,
        name: key,
        role: "tabpanel",
        aria: {
          hidden: (default != key).to_s,
          labelledby: tab_id(key, :tab)
        },
        data: data_merge({nk__tabs_target: "panel", key:}, attrs[:data]),
        class: merge(panel_class, attrs[:class])
      ) { yield }
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
      "border-b-2 border-transparent hover:border-primary focus-visible:border-primary cursor-pointer text-muted-foreground aria-[selected=true]:text-foreground font-medium aria-[selected=true]:border-primary -mb-px px-2"
    end

    def panel_class
      "aria-[hidden=true]:hidden py-4"
    end
  end
end
