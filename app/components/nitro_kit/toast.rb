# frozen_string_literal: true

module NitroKit
  class Toast < Component
    class FlashMessages < Component
      def initialize(flash)
        @flash = flash
      end

      attr_reader :flash

      def view_template
        flash.each do |severity, message|
          render(
            Toast::Item.new(
              description: message,
              variant: severity.to_sym == :alert ? :error : :default
            )
          )
        end
      end
    end

    class Item < Component
      VARIANTS = %i[default warning error success]

      def initialize(title: nil, description: nil, variant: :default, **attrs)
        @title = title
        @description = description
        @variant = variant

        super(
          **mattr(
            attrs,
            class: [
              base_class,
              variant_class
            ],
            role: "status",
            aria: {live: "off", atomic: "true"},
            tabindex: "0",
            data: {state: "closed"}
          )
        )
      end

      attr_reader :title, :description, :variant

      def view_template(&block)
        li(**attrs) do
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

      def base_class
        "shrink-0 pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md p-4 pr-8 shadow-lg transition-all border opacity-0 transition-all data-[state=open]:opacity-100 data-[state=open]:-translate-y-full"
      end

      def variant_class
        case variant
        when :default
          "border-border bg-background text-foreground"
        when :warning
          "bg-yellow-50 dark:bg-yellow-950 text-yellow-900 dark:text-yellow-100 border-yellow-500/80 dark:border-yellow-400/50"
        when :success
          "bg-green-50 dark:bg-green-950 text-green-900 dark:text-green-100 border-green-500/80 dark:border-green-400/50"
        when :error
          "bg-red-50 dark:bg-red-950 text-red-900 dark:text-red-100 border-red-400/80 dark:border-red-400/50"
        else
          raise ArgumentError, "Invalid variant `#{variant}'"
        end
      end
    end

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

      flash_sink

      template(data: {nk__toast_target: "template"}) do
        item
      end
    end

    builder_method def item(title: nil, description: nil, **attrs, &block)
      render(Item.new(title:, description:, **attrs), &block)
    end

    builder_method def flash_sink
      div(id: "nk--toast-sink", data: {nk__toast_target: "sink"}, hidden: true) do
        render(FlashMessages.new(view_context.flash))
      end
    end

    private

    def list_class
      "fixed z-[100] flex max-h-screen w-full p-5 bottom-0 right-0 flex-col h-0 md:max-w-[420px]"
    end
  end
end
