# frozen_string_literal: true

module NitroKit
  class Dropdown < Component
    PLACEMENTS = %i[bottom_start bottom_end top_start top_end].freeze
    ITEM_VARIANTS = %i[default destructive].freeze
    ITEM_TYPES = %i[button submit reset].freeze

    Trigger = ::Data.define(
      :text,
      :variant,
      :size,
      :icon,
      :icon_end,
      :label,
      :disabled,
      :html,
      :aria,
      :data,
      :css_class,
      :content
    )
    Entry = ::Data.define(
      :kind,
      :text,
      :href,
      :icon,
      :variant,
      :type,
      :disabled,
      :html,
      :aria,
      :data,
      :css_class,
      :content
    )

    def initialize(
      id: nil,
      placement: :bottom_start,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @placement = validate_choice!(:placement, placement, PLACEMENTS)
      @entries = []

      super(
        component: :dropdown,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--dropdown",
            placement: placement_value
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :placement

    def view_template(&block)
      collect_entries(&block)

      div(**root_attributes) do
        render_trigger
        render_content
      end
    end

    def trigger(
      text = nil,
      variant: :default,
      size: :md,
      icon: nil,
      icon_end: nil,
      label: nil,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      raise ArgumentError, "Dropdown accepts exactly one trigger" if @trigger
      if text.nil? && !content && icon.nil? && icon_end.nil?
        raise ArgumentError, "Dropdown trigger requires text, a block, or an icon"
      end

      @trigger = Trigger.new(
        text:,
        variant: validate_trigger_choice!(:variant, variant, Button::VARIANTS),
        size: validate_trigger_choice!(:size, size, Button::SIZES),
        icon:,
        icon_end:,
        label:,
        disabled: validate_boolean!(:disabled, disabled),
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
      nil
    end

    def title(text = nil, html: {}, aria: {}, data: {}, desperately_need_a_class: nil, &content)
      ensure_collecting!
      validate_content!(:title, text, content)
      add_entry(
        kind: :title,
        text:,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
    end

    def item(
      text = nil,
      href: nil,
      icon: nil,
      variant: :default,
      type: :button,
      disabled: false,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &content
    )
      ensure_collecting!
      validate_content!(:item, text, content)
      variant = validate_choice!(:variant, variant, ITEM_VARIANTS)
      type = validate_choice!(:type, type.to_s.to_sym, ITEM_TYPES)
      disabled = validate_boolean!(:disabled, disabled)
      if !href.nil? && (!href.is_a?(String) || href.empty?)
        raise ArgumentError, "Dropdown item href must be nil or a non-blank String"
      end

      add_entry(
        kind: :item,
        text:,
        href:,
        icon:,
        variant:,
        type:,
        disabled:,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class,
        content:
      )
    end

    def separator(html: {}, aria: {}, data: {}, desperately_need_a_class: nil)
      ensure_collecting!
      add_entry(
        kind: :separator,
        html:,
        aria:,
        data:,
        css_class: desperately_need_a_class
      )
    end

    private

    def collect_entries
      raise ArgumentError, "Dropdown requires a declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Dropdown requires one trigger" unless @trigger
      raise ArgumentError, "Dropdown requires at least one item" unless @entries.any? { |entry| entry.kind == :item }
    ensure
      @collecting = false
    end

    def render_trigger
      component = Button.new(
        @trigger.text,
        variant: @trigger.variant,
        size: @trigger.size,
        icon: @trigger.icon,
        icon_end: @trigger.icon_end,
        label: @trigger.label,
        disabled: @trigger.disabled,
        id: trigger_id,
        html: @trigger.html.merge(popovertarget: @trigger.disabled ? nil : content_id),
        aria: @trigger.aria.merge(haspopup: "menu"),
        data: owned_data(
          @trigger.data,
          nk__dropdown_target: "trigger",
          action: "keydown->nk--dropdown#openFromKeyboard"
        ),
        desperately_need_a_class: @trigger.css_class
      )
      if @trigger.content
        render_in_slot(component, :trigger) { render(@trigger.content) }
      else
        render_in_slot(component, :trigger)
      end
    end

    def render_content
      div(
        **slot_attributes(
          :content,
          attributes: {
            id: content_id,
            role: "menu",
            popover: "auto",
            tabindex: -1,
            aria: { labelledby: trigger_id },
            data: {
              placement: placement_value,
              nk__dropdown_target: "content",
              action: "beforetoggle->nk--dropdown#rememberFocus " \
                "toggle->nk--dropdown#focusOpened keydown->nk--dropdown#navigate"
            }
          }
        )
      ) do
        @entries.each { |entry| render_entry(entry) }
      end
    end

    def render_entry(entry)
      case entry.kind
      when :title then render_title(entry)
      when :item then render_item(entry)
      when :separator then render_separator(entry)
      end
    end

    def render_title(entry)
      div(
        **slot_attributes(
          :title,
          attributes: {
            role: "presentation",
            aria: { hidden: true }
          },
          html: entry.html,
          aria: entry.aria,
          data: entry.data,
          desperately_need_a_class: entry.css_class
        )
      ) { render_content_value(entry) }
    end

    def render_item(entry)
      native_attributes = if entry.href
        {
          href: entry.disabled ? nil : entry.href,
          tabindex: -1,
          aria: entry.aria.merge(disabled: entry.disabled ? true : nil)
        }
      else
        {
          type: entry.type,
          disabled: entry.disabled,
          tabindex: -1,
          aria: entry.aria
        }
      end

      attributes = slot_attributes(
        :item,
        attributes: native_attributes.merge(
          role: "menuitem",
          data: {
            nk__dropdown_target: "item",
            action: entry.disabled ? nil : "click->nk--dropdown#select"
          }
        ),
        html: entry.html,
        data: entry.data,
        variant: entry.variant,
        desperately_need_a_class: entry.css_class
      )

      public_send(entry.href ? :a : :button, **attributes) do
        if entry.icon
          span(**slot_attributes(:item_icon)) { render(Icon.new(entry.icon, size: :sm)) }
        end
        render_content_value(entry)
      end
    end

    def render_separator(entry)
      hr(
        **slot_attributes(
          :separator,
          attributes: { role: "separator" },
          html: entry.html,
          aria: entry.aria,
          data: entry.data,
          desperately_need_a_class: entry.css_class
        )
      )
    end

    def render_content_value(entry)
      entry.content ? render(entry.content) : plain(entry.text.to_s)
    end

    def add_entry(**attributes)
      @entries << Entry.new(**{
        kind: nil,
        text: nil,
        href: nil,
        icon: nil,
        variant: nil,
        type: nil,
        disabled: false,
        html: {},
        aria: {},
        data: {},
        css_class: nil,
        content: nil
      }.merge(attributes))
      nil
    end

    def validate_content!(name, text, content)
      return unless text.nil? && !content

      raise ArgumentError, "Dropdown #{name} requires text or a block"
    end

    def owned_data(data, **owned)
      action_key = data.keys.find { |key| key.to_s.tr("_", "-") == "action" }
      app_action = action_key && data[action_key]
      data.except(action_key).merge(
        owned.merge(action: [ owned[:action], app_action ].compact.join(" "))
      )
    end

    def placement_value
      placement.to_s.tr("_", "-")
    end

    def trigger_id
      "#{identifier}-trigger"
    end

    def content_id
      "#{identifier}-content"
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Dropdown declarations must be inside the render block"
    end

    def validate_trigger_choice!(name, value, choices)
      return value if choices.include?(value)

      raise ArgumentError,
        "Unknown Dropdown trigger #{name} #{value.inspect}; expected one of: #{choices.map(&:inspect).join(", ")}"
    end

    def component_id(value)
      return generated_id if value.nil?

      validate_id!("Dropdown id", value)
    end

    def generated_id
      "nk-dropdown-#{SecureRandom.hex(4)}"
    end
  end
end
