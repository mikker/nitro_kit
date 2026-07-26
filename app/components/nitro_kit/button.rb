# frozen_string_literal: true

module NitroKit
  class Button < Component
    VARIANTS = %i[default primary destructive ghost].freeze
    SIZES = %i[xs sm md lg xl].freeze
    TYPES = %i[button submit reset].freeze
    DEFAULT_TYPE = :button
    UNSET_TYPE = Object.new.freeze
    private_constant :UNSET_TYPE

    def initialize(
      text = nil,
      href: nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_end: nil,
      label: nil,
      id: nil,
      type: UNSET_TYPE,
      name: nil,
      value: nil,
      form: nil,
      target: nil,
      rel: nil,
      download: nil,
      disabled: false,
      loading: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      if !href.nil? && (!href.is_a?(String) || href.empty?)
        raise ArgumentError, "Button href must be nil or a non-blank String"
      end
      if href && !type.equal?(UNSET_TYPE)
        raise ArgumentError, "Link Buttons do not accept type; type: applies to native button elements"
      end
      if href && [ name, value, form ].any? { |option| !option.nil? }
        raise ArgumentError, "Link Buttons do not accept name, value, or form"
      end
      if !href && [ target, rel, download ].any? { |option| !option.nil? }
        raise ArgumentError, "Button elements do not accept target, rel, or download"
      end
      if !label.nil? && (!label.is_a?(String) || label.strip.empty?)
        raise ArgumentError, "Button label: must be a non-blank String"
      end
      if text.is_a?(String) && text.strip.empty?
        raise ArgumentError, "Button text must be non-blank"
      end

      @text = text
      @href = href
      @icon = icon
      @icon_end = icon_end
      @label = label
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @size = validate_choice!(:size, size, SIZES)
      @type = validate_choice!(:type, resolved_type(type), TYPES)
      @loading = validate_boolean!(:loading, loading)
      @disabled = validate_boolean!(:disabled, disabled) || @loading
      @aria = aria

      owned_aria = {
        label: @label,
        busy: @loading ? true : nil
      }.compact

      native_attributes = if href
        {
          id:,
          href: @disabled ? nil : href,
          target:,
          rel:,
          download:,
          tabindex: @disabled ? -1 : nil,
          aria: owned_aria
        }.compact.tap do |attributes|
          if @disabled
            attributes[:href] = nil
            attributes[:aria] = attributes[:aria].merge(disabled: true)
          end
          attributes.delete(:aria) if attributes[:aria].empty?
        end
      else
        { id:, type: @type, name:, value:, form:, disabled: @disabled, aria: owned_aria.presence }.compact
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

    attr_reader :text, :href, :icon, :icon_end, :label, :size, :variant

    def loading? = @loading

    def view_template(&block)
      raise ArgumentError, "Button accepts text or a block, not both" if !text.nil? && block
      unless !text.nil? || block || icon || icon_end
        raise ArgumentError, "Button requires text, a block, or an icon"
      end
      # Only render time knows whether a block supplies the visible label.
      if text.nil? && !block && !accessible_label?
        raise ArgumentError, "Icon-only Button requires label:, aria: { label: }, or aria: { labelledby: }"
      end

      tag = href ? :a : :button
      public_send(tag, **root_attributes) { contents(&block) }
    end

    private

    def resolved_type(type)
      return DEFAULT_TYPE if type.equal?(UNSET_TYPE)

      type.to_s.to_sym
    end

    def contents(&block)
      icon_only = text.nil? && !block
      spinner(icon_only:) if loading?
      icon_slot(icon, :icon_start, icon_only:) if icon && !loading?

      if block || !text.nil?
        span(**slot_attributes(:label)) do
          block ? yield : plain(text.to_s)
        end
      end

      icon_slot(icon_end, :icon_end, icon_only:) if icon_end
    end

    def spinner(icon_only:)
      span(**slot_attributes(:spinner, attributes: { aria: { hidden: true } })) do
        render(Icon.new(:"loader-circle", size: icon_only ? :md : icon_size))
      end
    end

    def icon_slot(name, slot, icon_only:)
      span(**slot_attributes(slot)) do
        render(Icon.new(name, size: icon_only ? :md : icon_size))
      end
    end

    def icon_size
      { xs: :xs, sm: :sm, md: :sm, lg: :md, xl: :md }.fetch(size)
    end

    def accessible_label?
      return true if @label

      %w[label labelledby].any? do |name|
        key = @aria.keys.find { |candidate| candidate.to_s.downcase.delete("_-") == name }
        value = key && @aria[key]
        value.is_a?(String) && !value.strip.empty?
      end
    end
  end
end
