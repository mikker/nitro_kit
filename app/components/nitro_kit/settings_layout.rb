# frozen_string_literal: true

module NitroKit
  class SettingsLayout < Component
    Region = Data.define(:label, :content, :html, :aria, :data, :css_class)

    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @navigation_region = nil
      @content_region = nil

      super(
        component: :settings_layout,
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
        render_navigation
        render_content
      end
    end

    def navigation(
      label:,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      raise ArgumentError, "SettingsLayout accepts exactly one navigation region" if @navigation_region
      unless label.is_a?(String) && !label.strip.empty?
        raise ArgumentError, "SettingsLayout navigation label must be a non-blank String"
      end

      @navigation_region = Region.new(
        label:,
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    def content(html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &block)
      raise ArgumentError, "SettingsLayout accepts exactly one content region" if @content_region
      @content_region = Region.new(
        label: nil,
        content: block,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
      nil
    end

    private

    def render_navigation
      region = @navigation_region
      nav(
        **slot_attributes(
          :navigation,
          attributes: { aria: { label: region.label } },
          html: region.html,
          aria: region.aria,
          data: region.data,
          desperately_need_a_class: region.css_class
        )
      ) { render(region.content) if region.content }
    end

    def render_content
      region = @content_region
      div(
        **slot_attributes(
          :content,
          html: region.html,
          aria: region.aria,
          data: region.data,
          desperately_need_a_class: region.css_class
        )
      ) { render(region.content) if region.content }
    end

    def validate_regions!
      raise ArgumentError, "SettingsLayout requires one navigation region" unless @navigation_region
      raise ArgumentError, "SettingsLayout requires one content region" unless @content_region
    end
  end
end
