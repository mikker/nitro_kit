# frozen_string_literal: true

module NitroKit
  class Fieldset < Component
    def initialize(legend: nil, description: nil, **attrs)
      @legend = legend
      @description = description
      super(
        attrs,
        class: base_class
      )
    end

    def view_template
      fieldset(**attrs) do
        legend(@legend) if @legend
        description(@description) if @description

        yield
      end
    end

    alias :html_legend :legend

    def legend(text = nil, **attrs, &block)
      builder do
        html_legend(**mattr(attrs, class: legend_class)) do
          text_or_block(text, &block)
        end
      end
    end

    def description(text = nil, **attrs, &block)
      builder do
        div(**mattr(attrs, class: description_class, data: {slot: "text"})) do
          text_or_block(text, &block)
        end
      end
    end

    private

    def base_class
      [
        "[&>*+[data-slot=control]]:mt-6 [&>*+[data-slot=text]]:mt-1",
        "[&+&]:mt-8"
      ]
    end

    def legend_class
      "text-lg font-semibold"
    end

    def description_class
      "text-sm text-muted-content"
    end
  end
end
