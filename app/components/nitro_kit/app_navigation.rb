# frozen_string_literal: true

module NitroKit
  class AppNavigation < Component
    alias_method :html_header, :header
    alias_method :html_footer, :footer
    alias_method :html_section, :section

    Item = ::Data.define(:text, :href, :icon, :badge, :current)
    Section = ::Data.define(:label, :entries)
    Entry = ::Data.define(:kind)

    def initialize(
      label:,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @label = validate_text!(:label, label)
      @entries = []

      super(
        component: :app_navigation,
        attributes: { id:, aria: { label: @label } }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :label

    def view_template(&declarations)
      collect_structure(&declarations)
      collect_body

      nav(**root_attributes) do
        render_header
        render_body
        render_footer
      end
    end

    def header(&content)
      ensure_phase!(:structure, :header)
      raise ArgumentError, "AppNavigation accepts at most one header" if @header
      raise ArgumentError, "AppNavigation header requires a block" unless content

      @header = content
      nil
    end

    def body(&content)
      ensure_phase!(:structure, :body)
      raise ArgumentError, "AppNavigation accepts exactly one body" if @body
      raise ArgumentError, "AppNavigation body requires a block" unless content

      @body = content
      nil
    end

    def footer(&content)
      ensure_phase!(:structure, :footer)
      raise ArgumentError, "AppNavigation accepts at most one footer" if @footer
      raise ArgumentError, "AppNavigation footer requires a block" unless content

      @footer = content
      nil
    end

    def section(label: nil, &content)
      ensure_phase!(:body, :section)
      raise ArgumentError, "AppNavigation section requires a block" unless content

      entries = []
      previous_entries = @entry_target
      previous_phase = @phase

      begin
        @entry_target = entries
        @phase = :section
        output = capture(self, &content)
        reject_rendered_output!(:section, output)
        unless entries.any?(Item)
          raise ArgumentError, "AppNavigation section requires at least one item"
        end
        previous_entries << Section.new(label: validate_optional_text!(:label, label), entries:)
        nil
      ensure
        @entry_target = previous_entries
        @phase = previous_phase
      end
    end

    def item(text, href:, icon: nil, badge: nil, current: false)
      ensure_entry_phase!(:item)
      text = validate_text!(:text, text)
      href = validate_text!(:href, href)
      icon = validate_icon_name!(icon)
      badge = validate_badge!(badge)
      current = validate_boolean!(:current, current)

      if current && @current_item
        raise ArgumentError, "AppNavigation accepts at most one current item"
      end

      @current_item = true if current
      @entry_target << Item.new(text:, href:, icon:, badge:, current:)
      @item_count += 1
      nil
    end

    def divider
      ensure_entry_phase!(:divider)
      @entry_target << Entry.new(kind: :divider)
      nil
    end

    def spacer
      ensure_phase!(:body, :spacer)
      raise ArgumentError, "AppNavigation accepts at most one spacer" if @spacer

      @spacer = true
      @entry_target << Entry.new(kind: :spacer)
      nil
    end

    private

    def collect_structure
      raise ArgumentError, "AppNavigation requires a declaration block" unless block_given?

      @phase = :structure
      output = capture(self) { |navigation| yield navigation }
      reject_rendered_output!(:structure, output)
      raise ArgumentError, "AppNavigation requires exactly one body" unless @body
    ensure
      @phase = nil
    end

    def collect_body
      @phase = :body
      @entry_target = @entries
      @item_count = 0
      output = capture(self, &@body)
      reject_rendered_output!(:body, output)
      raise ArgumentError, "AppNavigation body requires at least one item" if @item_count.zero?
    ensure
      @entry_target = nil
      @phase = nil
    end

    def render_header
      html_header(**slot_attributes(:header)) { render(@header) } if @header
    end

    def render_body
      div(**slot_attributes(:body)) do
        @entries.each { |entry| render_entry(entry) }
      end
    end

    def render_footer
      html_footer(**slot_attributes(:footer)) { render(@footer) } if @footer
    end

    def render_entry(entry)
      case entry
      when Item then render_item(entry)
      when Section then render_section(entry)
      else entry.kind == :divider ? render_divider : render_spacer
      end
    end

    def render_section(entry)
      html_section(**slot_attributes(:section)) do
        h2(**slot_attributes(:section_label)) { plain(entry.label) } if entry.label
        entry.entries.each { |child| render_entry(child) }
      end
    end

    def render_item(entry)
      a(
        **slot_attributes(
          :item,
          attributes: {
            href: entry.href,
            aria: { current: entry.current ? "page" : nil },
            data: { state: entry.current ? "current" : "default" }
          }
        )
      ) do
        render_in_slot(Icon.new(entry.icon, size: :sm), :item_icon) if entry.icon
        span(**slot_attributes(:item_label)) { plain(entry.text) }
        render_in_slot(Badge.new(entry.badge, size: :sm, color: :neutral), :item_badge) if entry.badge
      end
    end

    def render_divider
      hr(**slot_attributes(:divider))
    end

    def render_spacer
      div(**slot_attributes(:spacer, aria: { hidden: true }))
    end

    def ensure_phase!(expected, declaration)
      return if @phase == expected

      location = expected == :structure ? "the render block" : "the body"
      raise ArgumentError, "AppNavigation #{declaration} must be declared directly inside #{location}"
    end

    def ensure_entry_phase!(declaration)
      return if %i[body section].include?(@phase)

      raise ArgumentError, "AppNavigation #{declaration} must be declared inside the body or a section"
    end

    def reject_rendered_output!(location, output)
      return if output.empty?

      raise ArgumentError, "AppNavigation #{location} accepts declarations, not rendered content"
    end

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, value)
      return if value.nil?

      validate_text!(name, value)
    end

    def validate_icon_name!(value)
      return if value.nil?
      return value if (value.is_a?(String) || value.is_a?(Symbol)) && !value.to_s.strip.empty?

      raise ArgumentError, "icon must be a non-blank String or Symbol"
    end

    def validate_badge!(value)
      return if value.nil?

      if value.is_a?(String)
        return value unless value.strip.empty?

        raise ArgumentError, "badge must be a non-blank String or Numeric"
      end

      return value.to_s if value.is_a?(Numeric)

      raise ArgumentError, "badge must be a non-blank String or Numeric"
    end
  end
end
