# frozen_string_literal: true

module NitroKit
  class Tooltip < Component
    PLACEMENTS = %i[top right bottom left].freeze

    Trigger = ::Data.define(:text, :variant, :size, :disabled, :html, :aria, :data, :css_class, :content)

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
            state: "closed",
            nk__tooltip_open_value: "false"
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
              role: "tooltip",
              hidden: true,
              data: {
                state: "closed",
                nk__tooltip_target: "content"
              }
            }
          )
        ) { plain(content) }
      end
    end

    def trigger(
      text = nil,
      variant: :default,
      size: :md,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Tooltip accepts exactly one trigger" if @trigger
      raise ArgumentError, "Tooltip trigger requires text or a block" if text.nil? && !content

      @trigger = Trigger.new(
        text:,
        variant:,
        size:,
        disabled: false,
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
      component = Button.new(
        @trigger.text,
        variant: @trigger.variant,
        size: @trigger.size,
        disabled: @trigger.disabled,
        id: trigger_id,
        html: @trigger.html,
        aria: @trigger.aria.merge(describedby: content_id),
        data: owned_data(@trigger.data),
        desperately_need_a_class: @trigger.css_class
      )

      if @trigger.content
        render_in_slot(component, :trigger) { render(@trigger.content) }
      else
        render_in_slot(component, :trigger)
      end
    end

    def owned_data(data)
      action_key = data.keys.find { |key| key.to_s.tr("_", "-") == "action" }
      app_action = action_key && data[action_key]
      data.except(action_key).merge(
        action: [
          "pointerenter->nk--tooltip#open",
          "pointerleave->nk--tooltip#close",
          "focusin->nk--tooltip#open",
          "focusout->nk--tooltip#close",
          "keydown.esc->nk--tooltip#close",
          app_action
        ].compact.join(" ")
      )
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
