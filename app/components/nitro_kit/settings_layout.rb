# frozen_string_literal: true

module NitroKit
  class SettingsLayout < Component
    Item = ::Data.define(:text, :href, :icon, :current)

    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @label = nil
      @items = []
      @content = nil
      @phase = nil
      @navigation_declared = false
      @current_item = false

      super(
        component: :settings_layout,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template(&declarations)
      collect_regions(&declarations)

      div(**root_attributes) do
        render_navigation
        render_content
      end
    end

    def navigation(label:, &declarations)
      ensure_phase!(:structure, :navigation)
      raise ArgumentError, "SettingsLayout accepts exactly one navigation region" if @navigation_declared
      raise ArgumentError, "SettingsLayout navigation requires a block" unless declarations

      @label = validate_text!(:label, label)
      @navigation_declared = true
      collect_items(&declarations)
      nil
    end

    def item(text, href:, icon: nil, current: false)
      ensure_phase!(:navigation, :item)
      text = validate_text!(:text, text)
      href = validate_text!(:href, href)
      icon = item_icon(icon)
      current = validate_boolean!(:current, current)

      if current && @current_item
        raise ArgumentError, "SettingsLayout accepts at most one current item"
      end

      @current_item = true if current
      @items << Item.new(text:, href:, icon:, current:)
      nil
    end

    def content(&block)
      ensure_phase!(:structure, :content)
      raise ArgumentError, "SettingsLayout accepts exactly one content region" if @content
      raise ArgumentError, "SettingsLayout content requires a block" unless block

      @content = block
      nil
    end

    private

    def collect_regions
      raise ArgumentError, "SettingsLayout requires a declaration block" unless block_given?

      @phase = :structure
      output = capture(self) { |layout| yield layout }
      reject_rendered_output!(:structure, output)
      raise ArgumentError, "SettingsLayout requires one navigation region" unless @navigation_declared
      raise ArgumentError, "SettingsLayout requires one content region" unless @content
    ensure
      @phase = nil
    end

    def collect_items(&declarations)
      @phase = :navigation
      output = capture(self, &declarations)
      reject_rendered_output!(:navigation, output)
      raise ArgumentError, "SettingsLayout navigation requires at least one item" if @items.empty?
    ensure
      @phase = :structure
    end

    def render_navigation
      nav(**slot_attributes(:navigation, attributes: { aria: { label: @label } })) do
        ul(**slot_attributes(:items)) do
          @items.each { |item| render_item(item) }
        end
      end
    end

    def render_item(item)
      li(**slot_attributes(:item)) do
        a(
          **slot_attributes(
            :item_link,
            attributes: {
              href: item.href,
              aria: { current: item.current ? "page" : nil },
              data: { state: item.current ? "current" : "default" }
            }
          )
        ) do
          render_in_slot(item.icon, :item_icon) if item.icon
          plain(item.text)
        end
      end
    end

    def render_content
      div(**slot_attributes(:content)) { render(@content) }
    end

    def ensure_phase!(expected, declaration)
      return if @phase == expected

      location = expected == :structure ? "the render block" : "the navigation block"
      raise ArgumentError, "SettingsLayout #{declaration} must be declared directly inside #{location}"
    end

    def reject_rendered_output!(location, output)
      return if output.empty?

      raise ArgumentError, "SettingsLayout #{location} accepts declarations, not rendered content"
    end

    def item_icon(value)
      return if value.nil?

      unless (value.is_a?(String) || value.is_a?(Symbol)) && !value.to_s.strip.empty?
        raise ArgumentError, "SettingsLayout icon must be a non-blank String or Symbol"
      end

      Icon.new(value, size: :sm)
    end

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "SettingsLayout #{name} must be a non-blank String"
    end
  end
end
