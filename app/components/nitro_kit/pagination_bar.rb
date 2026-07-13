# frozen_string_literal: true

module NitroKit
  class PaginationBar < Component
    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @summary_rendered = false
      @pagination_rendered = false

      super(
        component: :pagination_bar,
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

    def summary(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "PaginationBar accepts at most one summary" if @summary_rendered
      unless block || (text.is_a?(String) && !text.strip.empty?)
        raise ArgumentError, "PaginationBar summary requires non-blank text or a block"
      end

      @summary_rendered = true
      p(
        **slot_attributes(
          :summary,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    def pagination(component, &content)
      raise ArgumentError, "PaginationBar accepts exactly one Pagination" if @pagination_rendered
      unless component.is_a?(NitroKit::Pagination)
        raise ArgumentError, "PaginationBar pagination must be a NitroKit::Pagination"
      end

      @pagination_rendered = true
      render_in_slot(component, :pagination, &content)
    end

    private

    def validate_regions!
      return if @pagination_rendered

      raise ArgumentError, "PaginationBar requires one Pagination"
    end
  end
end
