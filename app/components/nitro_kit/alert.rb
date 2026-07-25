# frozen_string_literal: true

module NitroKit
  class Alert < Component
    VARIANTS = %i[default warning error success].freeze
    COLORS = NitroKit::Badge::COLORS
    VARIANT_COLORS = {
      default: :zinc,
      warning: :amber,
      error: :red,
      success: :green
    }.freeze
    LIVE_MODES = %i[off polite assertive].freeze
    Region = Data.define(:text, :content, :html, :aria, :data, :css_class)
    Child = Data.define(:component, :content)

    def initialize(
      variant: :default,
      color: nil,
      live: :off,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @color = validate_choice!(:color, color || VARIANT_COLORS.fetch(@variant), COLORS)
      @live = validate_choice!(:live, live, LIVE_MODES)
      @icon = nil
      @title = nil
      @description = nil

      super(
        component: :alert,
        attributes: { id:, role: live_role, data: { color: @color } },
        html:,
        aria:,
        data:,
        variant:,
        desperately_need_a_class:
      )
    end

    attr_reader :variant

    def view_template
      yield self if block_given?

      div(**root_attributes) do
        render_in_slot(@icon.component, :icon, &@icon.content) if @icon
        render_region(:title, @title) if @title
        render_region(:description, @description) if @description
      end
    end

    def icon(component, &block)
      raise ArgumentError, "Alert accepts at most one icon" if @icon
      unless component.is_a?(NitroKit::Component)
        raise ArgumentError, "Alert icon must be a NitroKit::Component"
      end

      @icon = Child.new(component:, content: block)
      nil
    end

    def title(
      text = nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      @title = declare_region(:title, @title, text, block, html, aria, data, desperately_need_a_class)
      nil
    end

    def description(
      text = nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      @description = declare_region(
        :description,
        @description,
        text,
        block,
        html,
        aria,
        data,
        desperately_need_a_class
      )
      nil
    end

    private

    def declare_region(name, current, text, content, html, aria, data, css_class)
      raise ArgumentError, "Alert accepts at most one #{name}" if current
      raise ArgumentError, "Alert #{name} accepts text or a block, not both" if !text.nil? && content
      validate_content_text!("Alert #{name}", text) unless content

      Region.new(text:, content:, html:, aria:, data:, css_class:)
    end

    def render_region(name, region)
      div(
        **slot_attributes(
          name,
          html: region.html,
          aria: region.aria,
          data: region.data,
          desperately_need_a_class: region.css_class
        )
      ) do
        text_or_block(region.text, &region.content)
      end
    end

    def live_role
      { off: nil, polite: "status", assertive: "alert" }.fetch(@live)
    end
  end
end
