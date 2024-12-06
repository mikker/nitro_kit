# frozen_string_literal: true

module NitroKit
  class Dropdown < Component
    include Phlex::Rails::Helpers::LinkTo

    CONTENT = [
      "w-max-content absolute top-0 left-0",
      "p-1 bg-background rounded-md border shadow-sm",
      "w-fit max-w-sm flex-col text-left",
      "[&[aria-hidden=true]]:hidden flex"
    ].freeze

    TRIGGER = "inline-block"

    TITLE = "px-3 pt-2 pb-1.5 text-muted-foreground text-sm"

    ITEM = [
      "px-3 py-1.5 rounded",
      "font-medium truncate",
      "cursor-default"
    ].freeze

    ITEM_VARIANTS = {
      default: ["hover:bg-muted"],
      destructive: ["text-destructive-foreground hover:bg-destructive hover:text-white"]
    }.freeze

    SEPARATOR = "border-t my-1 -mx-1"

    def initialize(placement: nil, **attrs)
      @placement = placement
      @attrs = attrs
    end

    attr_reader :placement

    def view_template(&block)
      div(
        **attrs,
        data: data_merge(
          {:controller => "nk--dropdown", :"nk--dropdown-placement-value" => placement},
          attrs[:data]
        ),
        &block
      )
    end

    def trigger(**attrs, &block)
      div(
        aria: {haspopup: "true", expanded: "false"},
        **attrs,
        class: merge([TRIGGER, attrs[:class]]),
        data: data_merge(
          {:"nk--dropdown-target" => "trigger", :action => "click->nk--dropdown#toggle"},
          attrs[:data]
        ),
        &block
      )
    end

    def content(**attrs, &block)
      div(
        role: "menu",
        aria: {hidden: "true"},
        **attrs,
        class: merge([CONTENT, attrs[:class]]),
        data: data_merge(
          {:"nk--dropdown-target" => "content"},
          attrs[:data]
        ),
        &block
      )
    end

    def title(text = nil, **attrs, &block)
      class_list = merge([TITLE, attrs[:class]])
      div(**attrs, class: class_list) { text || block.call }
    end

    def item(
      text = nil,
      href = nil,
      variant: :default,
      **attrs
    )
      common_attrs = {
        role: "menuitem",
        tabindex: "-1",
        **attrs,
        class: merge([ITEM, ITEM_VARIANTS[variant], attrs[:class]])
      }

      if href
        link_to(href, **common_attrs) do
          text || yield
        end
      else
        div(**common_attrs) do
          text || yield
        end
      end
    end

    def destructive_item(*args, **attrs, &block)
      item(*args, **attrs, variant: :destructive, &block)
    end

    def separator
      div(class: SEPARATOR)
    end
  end
end
