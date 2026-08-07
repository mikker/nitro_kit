# frozen_string_literal: true

module NitroKit
  class Tooltip < Component
    PLACEMENTS = %i[top right bottom left].freeze
    HTML_TRIGGERS = %i[div span].freeze

    TriggerAttributes = ::Data.define(:html, :aria, :data)

    Trigger = ::Data.define(
      :as,
      :text,
      :href,
      :variant,
      :size,
      :icon,
      :icon_end,
      :label,
      :target,
      :rel,
      :download,
      :html,
      :aria,
      :data,
      :css_class,
      :content
    )

    def initialize(
      id:,
      content:,
      placement: :top,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @content = tooltip_content(content)
      @placement = validate_choice!(:placement, placement, PLACEMENTS)

      super(
        component: :tooltip,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--tooltip",
            placement: @placement,
            dismissed: nil,
            action: "keydown.esc@document->nk--tooltip#dismiss pointerleave->nk--tooltip#resetIfUninterested focusout->nk--tooltip#resetIfUninterested"
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :content, :placement

    def view_template(&block)
      collect_trigger(&block)

      span(**root_attributes) do
        render_trigger
        span(
          **slot_attributes(
            :content,
            attributes: {
              id: content_id,
              role: "tooltip"
            }
          )
        ) { plain(content) }
      end
    end

    def trigger(
      text = nil,
      as: Button,
      href: nil,
      variant: nil,
      size: nil,
      icon: nil,
      icon_end: nil,
      label: nil,
      target: nil,
      rel: nil,
      download: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Tooltip accepts exactly one trigger" if @trigger
      unless as == Button || as == :custom || HTML_TRIGGERS.include?(as)
        raise ArgumentError, "Tooltip as: must be NitroKit::Button, :custom, :div, or :span"
      end
      if text.nil? && !content && icon.nil?
        raise ArgumentError, "Tooltip trigger requires text, a block, or an icon"
      end
      if as == :custom && content&.arity != 1
        raise ArgumentError, "Tooltip custom trigger block must accept trigger attributes"
      end
      if as != Button && [ href, variant, size, icon, icon_end, label, target, rel, download ].any?
        raise ArgumentError, "Tooltip #{as.inspect} trigger does not accept Button options"
      end

      @trigger = Trigger.new(
        as:,
        text:,
        href:,
        variant: variant || :default,
        size: size || :md,
        icon:,
        icon_end:,
        label:,
        target:,
        rel:,
        download:,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
      nil
    end

    private

    def collect_trigger
      raise ArgumentError, "Tooltip requires a trigger declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Tooltip requires one trigger" unless @trigger
    ensure
      @collecting = false
    end

    def render_trigger
      return render_custom_trigger if @trigger.as == :custom
      return render_html_trigger if HTML_TRIGGERS.include?(@trigger.as)

      component = Button.new(
        @trigger.text,
        href: @trigger.href,
        variant: @trigger.variant,
        size: @trigger.size,
        icon: @trigger.icon,
        icon_end: @trigger.icon_end,
        label: @trigger.label,
        target: @trigger.target,
        rel: @trigger.rel,
        download: @trigger.download,
        id: trigger_id,
        html: @trigger.html,
        aria: with_description(@trigger.aria),
        data: owned_data(@trigger.data),
        desperately_need_a_class: @trigger.css_class
      )

      if @trigger.content
        render_in_slot(component, :trigger) { render(@trigger.content) }
      else
        render_in_slot(component, :trigger)
      end
    end

    def render_html_trigger
      attributes = trigger_attributes
      unless attributes.html.keys.any? { |key| normalized_attribute(key) == "tabindex" }
        attributes.html[:tabindex] = 0
      end

      public_send(
        @trigger.as,
        **slot_attributes(
          :trigger,
          attributes: attributes.html,
          aria: attributes.aria,
          data: attributes.data
        )
      ) { text_or_block(@trigger.text, &@trigger.content) }
    end

    def render_custom_trigger
      div(**slot_attributes(:trigger)) do
        raw(safe(capture(trigger_attributes, &@trigger.content)))
      end
    end

    def trigger_attributes
      TriggerAttributes.new(
        html: merge_distinct_attributes({ id: trigger_id }, @trigger.html),
        aria: with_description(@trigger.aria),
        data: owned_data(@trigger.data)
      )
    end

    def owned_data(data)
      action_key = data.keys.find { |key| key.to_s.tr("_", "-") == "action" }
      app_action = action_key && data[action_key]
      data.except(action_key).merge(
        action: [
          "keydown.esc->nk--tooltip#dismiss",
          app_action
        ].compact.join(" ")
      )
    end

    def with_description(aria)
      unless aria.is_a?(Hash)
        raise ArgumentError, "aria must be a Hash"
      end

      key = aria.keys.find { |candidate| candidate.to_s.downcase.delete("_-") == "describedby" }
      descriptions = key ? aria.fetch(key).to_s.split : []

      aria.except(key).merge(describedby: (descriptions + [ content_id ]).uniq.join(" "))
    end

    def trigger_id
      "#{identifier}-trigger"
    end

    def content_id
      "#{identifier}-content"
    end

    def tooltip_content(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Tooltip content must be a non-blank String"
    end

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "Tooltip id must be a non-blank String without whitespace"
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Tooltip trigger must be declared inside the render block"
    end
  end
end
