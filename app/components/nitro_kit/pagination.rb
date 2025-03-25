# frozen_string_literal: true

module NitroKit
  class Pagination < Component
    def initialize(**attrs)
      super(
        attrs,
        class: merge_class(nav_class, attrs[:class]),
        aria: {label: "Pagination"}
      )
    end

    def view_template
      nav(**attrs) do
        yield
      end
    end

    builder_method def prev(text = nil, **attrs, &block)
      page_link(**mattr(attrs, aria: {label: "Previous page"})) do
        if text || block_given?
          text_or_block(text, &block)
        else
          render(Icon.new("arrow-left"))
          plain("Previous")
        end
      end
    end

    builder_method def next(text = nil, **attrs, &block)
      page_link(**mattr(attrs, aria: {label: "Next page"})) do
        if text || block_given?
          text_or_block(text, &block)
        else
          plain("Next")
          render(Icon.new("arrow-right"))
        end
      end
    end

    builder_method def page(text = nil, current: false, **attrs, &block)
      page_link(
        **mattr(
          attrs,
          aria: {
            current: current ? "page" : nil
          },
          disabled: current,
          class: [page_class, current && "bg-zinc-200/50 dark:bg-zinc-800/50"]
        )
      ) do
        text_or_block(text, &block)
      end
    end

    builder_method def ellipsis(**attrs)
      render(
        Button.new(
          **mattr(
            attrs,
            variant: :ghost,
            disabled: true,
            class: page_class
          )
        )
      ) do
        "…"
      end
    end

    private

    def page_link(text = nil, disabled: nil, **attrs)
      a(
        **mattr(
          attrs,
          role: "link",
          aria: {disabled: disabled.to_s},
          class: link_class
        )
      ) do
        yield
      end
    end

    def nav_class
      "flex items-center justify-center gap-1 text-sm font-medium"
    end

    def link_class
      "inline-flex items-center justify-center rounded-md border font-medium h-9 px-3 gap-2 border-transparent aria-disabled:text-muted-content [&>svg]:size-4"
    end

    def page_class
      "w-9 px-0"
    end
  end
end
