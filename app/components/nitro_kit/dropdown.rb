# frozen_string_literal: true

module NitroKit
  class Dropdown < Component
    ITEM_VARIANTS = %i[default destructive]

    include Phlex::Rails::Helpers::LinkTo

    def initialize(placement: nil, **attrs)
      @placement = placement

      super(
        attrs,
        data: {
          controller: "nk--dropdown",
          nk__dropdown_placement_value: placement
        }
      )
    end

    attr_reader :placement

    def view_template
      div(**mattr(attrs)) do
        yield
      end
    end

    def trigger(text = nil, **attrs, &block)
      render(
        NitroKit::Button.new(
          **mattr(
            attrs,
            aria: {haspopup: "true", expanded: "false"},
            class: trigger_class,
            data: {nk__dropdown_target: "trigger", action: "click->nk--dropdown#toggle"}
          )
        )
      ) do
        text_or_block(text, &block)
      end
    end

    def content(**attrs)
      div(
        **mattr(
          attrs,
          role: "menu",
          aria: {hidden: "true"},
          class: content_class,
          data: {nk__dropdown_target: "content"},
          popover: true
        )
      ) do
        yield
      end
    end

    def title(text = nil, **attrs, &block)
      div(**mattr(attrs, class: title_class)) do
        text_or_block(text, &block)
      end
    end

    def item(
      text = nil,
      href = nil,
      variant: :default,
      **attrs,
      &block
    )
      common_attrs = mattr(
        attrs,
        role: "menuitem",
        tabindex: "-1",
        class: [item_class, item_variant_class(variant)]
      )

      if href
        link_to(href, **common_attrs) do
          text_or_block(text, &block)
        end
      else
        div(**common_attrs) do
          text_or_block(text, &block)
        end
      end
    end

    def destructive_item(*args, **attrs, &block)
      item(*args, **attrs, variant: :destructive, &block)
    end

    def separator
      hr(class: separator_class)
    end

    private

    def content_class
      [
        "z-10 w-max-content absolute top-0 left-0",
        "p-1 bg-background text-foreground rounded-md border shadow-sm",
        "w-fit max-w-sm flex-col text-left",
        "[&[aria-hidden=true]]:hidden flex"
      ]
    end

    def trigger_class
      ""
    end

    def title_class
      "px-3 pt-2 pb-1.5 text-muted-foreground text-sm"
    end

    def item_class
      [
        "px-3 py-1.5 rounded",
        "font-medium truncate",
        "cursor-default"
      ]
    end

    def item_variant_class(variant)
      case variant
      when :default
        "hover:bg-muted"
      when :destructive
        "text-destructive-foreground hover:bg-destructive hover:text-white"
      else
        raise ArgumentError, "Unknown variant: #{variant.inspect}"
      end
    end

    def separator_class
      "border-t my-1 -mx-1"
    end
  end
end
