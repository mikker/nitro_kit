# frozen_string_literal: true

module NitroKit
  class Alert < Component
    VARIANTS = %i[default warning error success]

    def initialize(variant: :default, **attrs)
      super(**attrs)
      @variant = variant
    end

    attr_reader :variant

    def view_template(&block)
      div(
        **attrs,
        role: "alert",
        class: merge(
          base_class,
          variant_class,
          attrs[:class]
        ),
        &block
      )
    end

    def title(text = nil, **attrs)
      h5(**attrs, class: merge(title_class, attrs[:class])) do
        text || (block_given? ? yield : "")
      end
    end

    def description(text = nil, **attrs)
      div(**attrs, class: merge(description_class, attrs[:class])) do
        text || (block_given? ? yield : "")
      end
    end

    private

    def base_class
      [
        "relative border w-full rounded-md p-5 text-sm space-y-2",
        "[&>svg~*]:pl-8 [&>svg]:absolute [&>svg]:top-5 [&>svg]:left-5"
      ]
    end

    def variant_class
      case variant
      when :default
        "border-border bg-background text-foreground"
      when :warning
        "bg-yellow-300/20 dark:bg-yellow-300/20 text-yellow-900 dark:text-yellow-100 border-yellow-500/80 dark:border-yellow-400/50"
      when :success
        "bg-green-300/20 dark:bg-green-300/20 text-green-900 dark:text-green-100 border-green-500/80 dark:border-green-400/50"
      when :error
        "bg-red-300/20 dark:bg-red-300/20 text-red-900 dark:text-red-100 border-red-400/80 dark:border-red-400/50"
      else
        raise ArgumentError, "Invalid variant: #{variant}"
      end
    end

    def title_class
      "font-medium text-lg leading-5"
    end

    def description_class
      ""
    end
  end
end
