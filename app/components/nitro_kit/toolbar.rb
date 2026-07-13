# frozen_string_literal: true

module NitroKit
  class Toolbar < Component
    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @leading_rendered = false
      @trailing_rendered = false

      super(
        component: :toolbar,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes) do
        yield self if block_given?
        validate_regions!
      end
    end

    def leading(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      raise ArgumentError, "Toolbar accepts at most one leading region" if @leading_rendered

      @leading_rendered = true
      div(
        **slot_attributes(
          :leading,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { yield if block_given? }
    end

    def trailing(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      raise ArgumentError, "Toolbar accepts at most one trailing region" if @trailing_rendered

      @trailing_rendered = true
      div(
        **slot_attributes(
          :trailing,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { yield if block_given? }
    end

    private

    def validate_regions!
      return if @leading_rendered || @trailing_rendered

      raise ArgumentError, "Toolbar requires a leading or trailing region"
    end
  end
end
