# frozen_string_literal: true

module NitroKit
  class Toolbar < Component
    Region = Data.define(:content, :html, :aria, :data, :css_class)

    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @leading_region = nil
      @trailing_region = nil

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
      yield self if block_given?
      validate_regions!

      div(**root_attributes) do
        render_region(:leading, @leading_region) if @leading_region
        render_region(:trailing, @trailing_region) if @trailing_region
      end
    end

    def leading(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "Toolbar accepts at most one leading region" if @leading_region
      @leading_region = Region.new(
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    def trailing(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "Toolbar accepts at most one trailing region" if @trailing_region
      @trailing_region = Region.new(
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    private

    def render_region(name, region)
      div(
        **slot_attributes(
          name,
          html: region.html,
          aria: region.aria,
          data: region.data,
          desperately_need_a_class: region.css_class
        )
      ) { render(region.content) if region.content }
    end

    def validate_regions!
      return if @leading_region || @trailing_region

      raise ArgumentError, "Toolbar requires a leading or trailing region"
    end
  end
end
