# frozen_string_literal: true

module NitroKit
  class Table < Component
    ALIGNMENTS = %i[left center right].freeze
    SCOPES = %i[col row].freeze

    def initialize(
      id: nil,
      html: {},
      aria: {},
      data: {},
      table_html: {},
      table_aria: {},
      table_data: {},
      desperately_need_a_class: nil
    )
      super(
        component: :table,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )

      @table_attributes = slot_attributes(
        :element,
        html: table_html,
        aria: table_aria,
        data: table_data
      )
    end

    def view_template
      div(**root_attributes) do
        table(**@table_attributes) { yield }
      end
    end

    alias :html_caption :caption
    alias :html_thead :thead
    alias :html_tbody :tbody
    alias :html_tr :tr
    alias :html_th :th
    alias :html_td :td

    def caption(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      html_caption(**slot_attributes(:caption, html:, aria:, data:, desperately_need_a_class:)) do
        text_or_block(text, &block)
      end
    end

    def thead(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      html_thead(**slot_attributes(:head, html:, aria:, data:, desperately_need_a_class:)) { yield }
    end

    def tbody(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      html_tbody(**slot_attributes(:body, html:, aria:, data:, desperately_need_a_class:)) { yield }
    end

    def tr(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      html_tr(**slot_attributes(:row, html:, aria:, data:, desperately_need_a_class:)) { yield }
    end

    def th(
      text = nil,
      align: :left,
      scope: :col,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      alignment = validate_choice!(:align, align, ALIGNMENTS)
      scope = validate_choice!(:scope, scope, SCOPES)
      html_th(
        **slot_attributes(
          :header,
          attributes: { scope:, data: { align: alignment } },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    def td(
      text = nil,
      align: :left,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      alignment = validate_choice!(:align, align, ALIGNMENTS)
      html_td(
        **slot_attributes(
          :cell,
          attributes: { data: { align: alignment } },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end
  end
end
