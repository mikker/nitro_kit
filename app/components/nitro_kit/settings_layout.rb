# frozen_string_literal: true

module NitroKit
  class SettingsLayout < Component
    def initialize(id: nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      @navigation_rendered = false
      @content_rendered = false

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
      div(**root_attributes) do
        yield self if block_given?
        validate_regions!
      end
    end

    def navigation(
      label:,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      raise ArgumentError, "SettingsLayout accepts exactly one navigation region" if @navigation_rendered
      unless label.is_a?(String) && !label.strip.empty?
        raise ArgumentError, "SettingsLayout navigation label must be a non-blank String"
      end

      @navigation_rendered = true
      nav(
        **slot_attributes(
          :navigation,
          attributes: { aria: { label: } },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { yield if block_given? }
    end

    def content(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      raise ArgumentError, "SettingsLayout accepts exactly one content region" if @content_rendered

      @content_rendered = true
      div(
        **slot_attributes(
          :content,
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      ) { yield if block_given? }
    end

    private

    def validate_regions!
      raise ArgumentError, "SettingsLayout requires one navigation region" unless @navigation_rendered
      raise ArgumentError, "SettingsLayout requires one content region" unless @content_rendered
    end
  end
end
