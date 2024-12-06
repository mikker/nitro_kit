# frozen_string_literal: true

module NitroKit
  class Pagination < Component
    def view_template
      nav(
        **attrs,
        class: merge(nav_class, attrs[:class]),
        aria: {
          label: "Pagination",
          **attrs.fetch(:aria, {})
        }
      ) do
        yield
      end
    end

    def prev(text = nil, **attrs)
      page_link(**attrs, aria: {label: "Previous page"}) do
        if text || block_given?
          text ? plain(text) : yield
        else
          render(Icon.new(name: "arrow-left"))
          plain("Previous")
        end
      end
    end

    def next(text = nil, **attrs)
      page_link(**attrs, aria: {label: "Next page"}) do
        if text || block_given?
          text ? plain(text) : yield
        else
          plain("Next")
          render(Icon.new(name: "arrow-right"))
        end
      end
    end

    def page(text = nil, current: false, **attrs)
      page_link(
        **attrs,
        aria: {
          current: current ? "page" : nil
        },
        disabled: current,
        class: merge(
          page_class,
          current && "bg-zinc-200/50",
          attrs[:class]
        )
      ) do
        text || (block_given? ? yield : "")
      end
    end

    def ellipsis(**attrs)
      render(
        Button.new(
          variant: :ghost,
          **attrs,
          disabled: true,
          class: merge(page_class, attrs[:class])
        )
      ) do
        "…"
      end
    end

    private

    def page_link(text = nil, disabled: nil, **attrs, &block)
      a(
        **attrs,
        role: "link",
        aria: {
          disabled: disabled.to_s,
          **attrs.fetch(:aria, {})
        },
        class: merge(
          link_class,
          attrs[:class]
        ),
        &block
      )
    end

    def nav_class
      "flex items-center justify-center gap-1 text-sm font-medium"
    end

    def link_class
      "inline-flex items-center justify-center rounded-md border font-medium h-9 px-3 gap-2 border-transparent aria-disabled:text-muted-foreground [&>svg]:size-4"
    end

    def page_class
      "w-9 px-0"
    end
  end
end
