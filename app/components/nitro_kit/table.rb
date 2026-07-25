# frozen_string_literal: true

module NitroKit
  class Table < Component
    ALIGNMENTS = %i[left center right].freeze
    SCOPES = %i[col row].freeze
    Section = Data.define(:content, :html, :aria, :data, :css_class)
    Caption = Data.define(:text, :content, :html, :aria, :data, :css_class)

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
      @caption = nil
      @head = nil
      @bodies = []
    end

    def view_template
      @collecting_sections = true
      yield self if block_given?
      @collecting_sections = false

      div(**root_attributes) do
        table(**@table_attributes) do
          render_caption if @caption
          render_section(:head, @head, :html_thead) if @head
          @bodies.each { |body| render_section(:body, body, :html_tbody) }
        end
      end
    ensure
      @collecting_sections = false
    end

    alias :html_caption :caption
    alias :html_thead :thead
    alias :html_tbody :tbody
    alias :html_tr :tr
    alias :html_th :th
    alias :html_td :td

    def caption(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      ensure_collecting_sections!(:caption)
      raise ArgumentError, "Table accepts at most one caption" if @caption
      raise ArgumentError, "Table caption accepts text or a block, not both" if !text.nil? && block
      validate_content_text!("Table caption", text) unless block

      @caption = Caption.new(
        text:,
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    def thead(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      ensure_collecting_sections!(:thead)
      raise ArgumentError, "Table accepts at most one thead" if @head
      raise ArgumentError, "Table thead requires a block" unless block

      @head = Section.new(content: block, html:, aria:, data:, css_class: desperately_need_a_class)
      nil
    end

    def tbody(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      ensure_collecting_sections!(:tbody)
      raise ArgumentError, "Table tbody requires a block" unless block

      @bodies << Section.new(content: block, html:, aria:, data:, css_class: desperately_need_a_class)
      nil
    end

    def tr(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "Table rows must be declared inside thead or tbody" unless @rendering_section
      raise ArgumentError, "Table tr requires a block" unless block

      html_tr(**slot_attributes(:row, html:, aria:, data:, desperately_need_a_class:)) do
        @rendering_row = true
        render(block)
      ensure
        @rendering_row = false
      end
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
      ensure_rendering_row!(:th)
      raise ArgumentError, "Table th accepts text or a block, not both" if !text.nil? && block
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
      ensure_rendering_row!(:td)
      raise ArgumentError, "Table td accepts text or a block, not both" if !text.nil? && block
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

    private

    def render_caption
      html_caption(
        **slot_attributes(
          :caption,
          html: @caption.html,
          aria: @caption.aria,
          data: @caption.data,
          desperately_need_a_class: @caption.css_class
        )
      ) { text_or_block(@caption.text, &@caption.content) }
    end

    def render_section(slot, section, tag)
      public_send(
        tag,
        **slot_attributes(
          slot,
          html: section.html,
          aria: section.aria,
          data: section.data,
          desperately_need_a_class: section.css_class
        )
      ) do
        @rendering_section = true
        render(section.content)
      ensure
        @rendering_section = false
      end
    end

    def ensure_collecting_sections!(name)
      return if @collecting_sections

      raise ArgumentError, "Table #{name} must be declared inside the render block"
    end

    def ensure_rendering_row!(name)
      return if @rendering_row

      raise ArgumentError, "Table #{name} must be declared inside tr"
    end
  end
end
