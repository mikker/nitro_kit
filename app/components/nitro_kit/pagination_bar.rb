# frozen_string_literal: true

module NitroKit
  class PaginationBar < Component
    Summary = Data.define(:text, :content, :html, :aria, :data, :css_class)
    Child = Data.define(:component, :content)

    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @summary = nil
      @pagination = nil

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
      yield self if block_given?
      validate_regions!

      div(**root_attributes) do
        render_summary if @summary
        render_in_slot(@pagination.component, :pagination, &@pagination.content)
      end
    end

    alias :html_summary :summary

    def summary(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "PaginationBar accepts at most one summary" if @summary
      raise ArgumentError, "PaginationBar summary accepts text or a block, not both" if !text.nil? && block
      unless block || (text.is_a?(String) && !text.strip.empty?)
        raise ArgumentError, "PaginationBar summary requires non-blank text or a block"
      end

      @summary = Summary.new(
        text:,
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    def pagination(component, &content)
      raise ArgumentError, "PaginationBar accepts exactly one Pagination" if @pagination
      unless component.is_a?(NitroKit::Pagination)
        raise ArgumentError, "PaginationBar pagination must be a NitroKit::Pagination"
      end

      @pagination = Child.new(component:, content:)
      nil
    end

    private

    def render_summary
      p(
        **slot_attributes(
          :summary,
          html: @summary.html,
          aria: summary_aria,
          data: @summary.data,
          desperately_need_a_class: @summary.css_class
        )
      ) { text_or_block(@summary.text, &@summary.content) }
    end

    # Turbo Frame page changes replace the summary in place, so it announces
    # politely unless the caller declares its own live region behavior.
    def summary_aria
      return @summary.aria if @summary.aria.keys.any? { |key| key.to_s.tr("_", "-") == "live" }

      @summary.aria.merge(live: "polite")
    end

    def validate_regions!
      return if @pagination

      raise ArgumentError, "PaginationBar requires one Pagination"
    end
  end
end
