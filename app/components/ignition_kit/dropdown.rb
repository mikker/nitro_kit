module IgnitionKit
  class Dropdown < Component
    include Phlex::Rails::Helpers::LinkTo

    TITLE_BASE = [
      "px-3 pt-2 pb-1.5",
      "text-muted-foreground text-sm"
    ].freeze

    CONTENT_BASE = [
      "w-max-content absolute top-0 left-0 hidden",
      "p-1 bg-background rounded-md border shadow-sm",
      "w-fit max-w-sm flex flex-col"
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

    def initialize(**attrs)
      @attrs = attrs
    end

    def view_template(&block)
      div(data: {controller: "ik--dropdown"}, &block)
    end

    def trigger(**attrs, &block)
      class_list = "inline-block"
      data = {
        :"ik--dropdown-target" => "trigger",
        :action => "click->ik--dropdown#toggle",
        **attrs.fetch(:data, {})
      }
      div(**attrs, class: class_list, data:, &block)
    end

    def content(**attrs, &block)
      class_list = merge([CONTENT_BASE, attrs[:class]])
      data = {
        :"ik--dropdown-target" => "content",
        **attrs.fetch(:data, {})
      }
      div(**attrs, class: class_list, data:, &block)
    end

    def title(text = nil, **attrs, &block)
      class_list = merge([TITLE_BASE, attrs[:class]])
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

      if href
        link_to(
          href,
          **attrs,
          class: class_list
        ) {
          text || block.call
        }
      else
        div(**attrs, class: class_list) { text || block.call }
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
