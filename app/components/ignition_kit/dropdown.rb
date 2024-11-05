module IgnitionKit
  class Dropdown < Component
    include Phlex::Rails::Helpers::LinkTo

    CONTENT_BASE = [
      "w-max-content absolute top-0 left-0",
      "p-1 bg-background rounded-md border shadow-sm",
      "w-fit max-w-sm flex-col",
      "[&[aria-hidden=true]]:hidden flex"
    ].freeze

    ITEM_BASE = [
      "px-3 py-1.5 rounded",
      "font-medium truncate",
      "cursor-default"
    ].freeze

    ITEM_VARIANTS = {
      default: ["hover:bg-muted"],
      destructive: ["text-destructive-foreground hover:bg-destructive hover:text-white"]
    }.freeze

    SEPARATOR_BASE = "border-t my-1 -mx-1"

    def initialize(placement: nil, **attrs)
      @placement = placement
      @attrs = attrs
    end

    attr_reader :placement

    def view_template(&block)
      div(data: {:controller => "ik--dropdown", :"ik--dropdown-placement-value" => placement}, &block)
    end

    def trigger(**attrs, &block)
      class_list = "inline-block"
      data = {
        :"ik--dropdown-target" => "trigger",
        :action => "click->ik--dropdown#toggle",
        **attrs.fetch(:data, {})
      }
      div(
        **attrs,
        class: class_list,
        data:,
        aria: {haspopup: "true", expanded: "false"},
        &block
      )
    end

    def content(**attrs, &block)
      class_list = merge([CONTENT_BASE, attrs[:class]])

      data = {
        :"ik--dropdown-target" => "content",
        **attrs.fetch(:data, {})
      }
      div(
        **attrs,
        class: class_list,
        data:,
        role: "menu",
        aria: {hidden: "true"},
        &block
      )
    end

    def title(text = nil, **attrs, &block)
      class_list = merge(["px-3 pt-2 pb-1.5 text-muted-foreground text-sm", attrs[:class]])
      div(**attrs, class: class_list) { text || block.call }
    end

    def item(
      text = nil,
      href: nil,
      variant: :default,
      **attrs,
      &block
    )
      class_list = merge([ITEM_BASE, ITEM_VARIANTS[variant], attrs[:class]])

      common_attrs = {
        **attrs,
        class: class_list,
        role: "menuitem",
        tabindex: "-1"
      }

      if href
        link_to(
          href,
          **common_attrs
        ) {
          text || block.call
        }
      else
        div(**common_attrs) { text || block.call }
      end
    end

    def destructive_item(text = nil, **attrs, &block)
      item(text, variant: :destructive, **attrs, &block)
    end

    def separator
      div(class: SEPARATOR_BASE)
    end
  end
end
