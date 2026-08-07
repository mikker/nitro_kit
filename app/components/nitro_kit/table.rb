# frozen_string_literal: true

module NitroKit
  class Table < Component
    ALIGNMENTS = %i[left center right].freeze
    DEFAULT_ALIGNMENT = :left
    SCOPES = %i[col row].freeze
    DIRECTIONS = %i[asc desc].freeze
    SORT_ICONS = { asc: "arrow-up", desc: "arrow-down", none: "chevrons-up-down" }.freeze
    Section = Data.define(:content, :html, :aria, :data, :css_class)
    Caption = Data.define(:text, :content, :html, :aria, :data, :css_class)

    # Table renders in two phases. `caption`, `thead`, and `tbody` only collect
    # declarations, so the component owns caption → head → body order regardless
    # of caller order. `tr`, `th`, and `td` run inside a collected block and
    # render immediately, which is why their validation raises before the cell
    # it describes is emitted rather than after the table is complete.
    def initialize(
      sort: nil,
      direction: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      table_html: {},
      table_aria: {},
      table_data: {},
      desperately_need_a_class: nil
    )
      @sort = sort.nil? ? nil : normalize_sort_key(sort, name: "sort")
      unless direction.nil? || direction.is_a?(Symbol) || direction.is_a?(String)
        raise ArgumentError, "Table direction must be a Symbol or String"
      end
      @direction = direction.nil? ? nil : validate_choice!(:direction, direction.to_sym, DIRECTIONS)
      unless @sort.nil? == @direction.nil?
        raise ArgumentError, "Table sort: and direction: must both be set or both be nil"
      end

      super(
        component: :table,
        attributes: { id:, data: { sort: @sort, direction: @direction }.compact }.compact,
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
      @caption_id = "#{id || "nk-table-#{SecureRandom.hex(4)}"}-caption"
      @head = nil
      @bodies = []
      @sort_keys = []
    end

    attr_reader :sort, :direction

    def view_template
      @collecting_sections = true
      yield self if block_given?
      @collecting_sections = false

      div(**scroll_region_attributes) do
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
      sort: nil,
      href: nil,
      sort_data: {},
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      ensure_rendering_row!(:th)
      raise ArgumentError, "Table th accepts text or a block, not both" if !text.nil? && block
      raise ArgumentError, "Table th href: requires sort:" if sort.nil? && !href.nil?
      raise ArgumentError, "Table th sort: must be declared inside thead" if !sort.nil? && @rendering_section != :head
      alignment = validate_choice!(:align, align, ALIGNMENTS)
      scope = validate_choice!(:scope, scope, SCOPES)
      key = sort.nil? ? nil : declare_sort_header!(sort, href:)

      html_th(
        **slot_attributes(
          :header,
          attributes: {
            scope:,
            aria: key ? { sort: aria_sort(key) } : {},
            data: { align: alignment_value(alignment), sort_key: key }.compact
          },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) do
        if key
          render_sort_link(key, text, href:, data: sort_data, &block)
        else
          text_or_block(text, &block)
        end
      end
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
          attributes: { data: { align: alignment_value(alignment) }.compact },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { text_or_block(text, &block) }
    end

    private

    def alignment_value(alignment)
      alignment unless alignment == DEFAULT_ALIGNMENT
    end

    def render_sort_link(key, text, href:, data:, &block)
      a(**slot_attributes(:sort, attributes: { href: }, data:)) do
        span(**slot_attributes(:sort_label)) do
          block ? text_or_block(nil, &block) : plain(text || key.humanize)
        end
        render_in_slot(
          Icon.new(SORT_ICONS.fetch(active_sort?(key) ? direction : :none), size: :xs),
          :sort_indicator
        )
      end
    end

    def active_sort?(key) = sort == key

    def aria_sort(key)
      return "none" unless active_sort?(key)

      direction == :asc ? "ascending" : "descending"
    end

    def declare_sort_header!(key, href:)
      key = normalize_sort_key(key, name: "th sort")
      unless href.is_a?(String) && !href.strip.empty?
        raise ArgumentError, "Table th sort: requires a non-blank String href:"
      end
      raise ArgumentError, "Table sort keys must be unique: #{key.inspect}" if @sort_keys.include?(key)

      @sort_keys << key
      key
    end

    def normalize_sort_key(value, name:)
      normalized = value.to_s.strip if value.is_a?(Symbol) || value.is_a?(String)
      return normalized if normalized.present?

      raise ArgumentError, "Table #{name} must be a Symbol or non-blank String"
    end

    # The wrapper scrolls horizontally, so keyboard users need it focusable and
    # named. The caption is the only Nitro-owned name source, so the region is
    # only exposed when one exists.
    def scroll_region_attributes
      return root_attributes unless @caption

      root_attributes.merge(
        tabindex: "0",
        role: "region",
        aria: root_attributes.fetch(:aria, {}).merge(labelledby: @caption_id)
      )
    end

    def render_caption
      html_caption(
        **slot_attributes(
          :caption,
          attributes: { id: @caption_id },
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
        @rendering_section = slot
        render(section.content)
      ensure
        @rendering_section = nil
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
