# frozen_string_literal: true

module NitroKit
  class Dialog < Component
    def initialize(identifier: nil, **attrs)
      @identifier = identifier || SecureRandom.hex(6)

      super(
        attrs,
        data: {controller: "nk--dialog", action: "click->nk--dialog#clickOutside"}
      )
    end

    attr_reader :identifier

    def view_template
      div(**attrs) do
        yield
      end
    end

    builder_method def trigger(text = nil, as: Button, **attrs, &block)
      trigger_attrs = mattr(
        attrs,
        data: {
          nk__dialog_target: "trigger",
          action: "click->nk--dialog#open"
        }
      )

      case as
      when Symbol
        send(as, **trigger_attrs) do
          text_or_block(text, &block)
        end
      else
        render(as.new(**trigger_attrs)) do
          text_or_block(text, &block)
        end
      end
    end

    alias :html_dialog :dialog

    builder_method def dialog(**attrs)
      html_dialog(
        **mattr(
          attrs,
          class: dialog_class,
          data: {nk__dialog_target: "dialog"},
          aria: {
            labelledby: id(:title),
            describedby: id(:description)
          }
        )
      ) do
        yield
      end
    end

    builder_method def close_button(**attrs)
      render(
        Button.new(
          **mattr(
            attrs,
            variant: :ghost,
            size: :sm,
            class: "absolute top-2 right-2",
            data: {action: "nk--dialog#close"}
          )
        )
      ) do
        render(Icon.new(:x))
      end
    end

    builder_method def title(text = nil, **attrs, &block)
      h2(**mattr(attrs, id: id(:title), class: "text-lg font-semibold mb-2")) do
        text_or_block(text, &block)
      end
    end

    builder_method def description(text = nil, **attrs, &block)
      div(
        **mattr(
          attrs,
          id: id(:description),
          class: "text-muted-content mb-6 text-sm leading-relaxed"
        )
      ) do
        text_or_block(text, &block)
      end
    end

    private

    def id(suffix = nil)
      "nk-#{identifier}#{suffix ? "-#{suffix}" : ""}"
    end

    def dialog_class
      [
        "border rounded-xl max-w-lg w-full bg-background text-foreground shadow-lg m-auto p-6",
        "dark:backdrop:bg-black/50"
      ]
    end
  end
end
