# frozen_string_literal: true

module NitroKit
  class Button < Component
    VARIANTS = %i[default primary destructive ghost].freeze
    SIZES = %i[xs sm md lg xl].freeze
    TYPES = %i[button submit reset].freeze

    def initialize(
      text = nil,
      href: nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_right: nil,
      id: nil,
      type: :button,
      name: nil,
      value: nil,
      form: nil,
      target: nil,
      rel: nil,
      download: nil,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @text = text
      @href = href
      @icon = icon
      @icon_right = icon_right
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @size = validate_choice!(:size, size, SIZES)
      @type = validate_choice!(:type, type.to_s.to_sym, TYPES)
      @disabled = validate_boolean!(:disabled, disabled)
      @aria = aria

      native_attributes = if href
        {
          id:,
          href: @disabled ? nil : href,
          target:,
          rel:,
          download:,
          tabindex: @disabled ? -1 : nil
        }.compact.tap do |attributes|
          if @disabled
            attributes[:href] = nil
            attributes[:aria] = { disabled: true }
          end
        end
      else
        { id:, type: @type, name:, value:, form:, disabled: @disabled }.compact
      end

      super(
        component: :button,
        attributes: native_attributes,
        html:,
        aria:,
        data:,
        variant:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :text, :href, :icon, :icon_right, :size, :variant

    def view_template(&block)
      raise ArgumentError, "Button requires text, a block, or an icon" unless !text.nil? || block || icon || icon_right
      if text.nil? && !block && !accessible_label?
        raise ArgumentError, "Icon-only Button requires a non-blank aria: { label: }"
      end

      tag = href ? :a : :button
      public_send(tag, **root_attributes) { contents(&block) }
    end

    private

    def contents(&block)
      icon_slot(icon, :icon_start) if icon

      if block || !text.nil?
        span(**slot_attributes(:label)) do
          block ? yield : plain(text.to_s)
        end
      end

      icon_slot(icon_right, :icon_end) if icon_right
    end

    def icon_slot(name, slot)
      span(**slot_attributes(slot)) do
        render(Icon.new(name, size: icon_size))
      end
    end

    def icon_size
      { xs: :xs, sm: :sm, md: :sm, lg: :md, xl: :md }.fetch(size)
    end

    def accessible_label?
      label_key = @aria.keys.find { |key| key.to_s.tr("_", "-") == "label" }
      label = @aria[label_key]
      label.is_a?(String) && !label.strip.empty?
    end
  end
end
