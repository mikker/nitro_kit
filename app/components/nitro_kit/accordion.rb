# frozen_string_literal: true

module NitroKit
  class Accordion < Component
    MODES = %i[multiple single].freeze
    Item = ::Data.define(:key, :title, :expanded, :disabled, :content)

    def initialize(
      id:,
      mode: :multiple,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = component_id(id)
      @mode = validate_choice!(:mode, mode, MODES)
      @items = []

      super(
        component: :accordion,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--accordion",
            mode: @mode,
            nk__accordion_mode_value: @mode
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :mode

    def view_template(&block)
      collect_items(&block)

      div(**root_attributes) do
        @items.each { |item| render_item(item) }
      end
    end

    def item(key, title:, expanded: false, disabled: false, &content)
      ensure_collecting!

      key = normalize_identity(key, name: "accordion item key")
      title = validate_title!(title)
      expanded = validate_boolean!(:expanded, expanded)
      disabled = validate_boolean!(:disabled, disabled)
      raise ArgumentError, "Accordion item #{key.inspect} requires content" unless content
      raise ArgumentError, "Duplicate accordion item key #{key.inspect}" if @items.any? { |item| item.key == key }

      if mode == :single && expanded && @items.any?(&:expanded)
        raise ArgumentError, "Single accordion mode accepts only one expanded item"
      end

      @items << Item.new(key:, title:, expanded:, disabled:, content:)
      nil
    end

    private

    def collect_items
      raise ArgumentError, "Accordion requires an item declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Accordion requires at least one item" if @items.empty?
    ensure
      @collecting = false
    end

    def render_item(item)
      state = item.expanded ? "open" : "closed"

      div(
        **slot_attributes(
          :item,
          attributes: {
            data: {
              key: item.key,
              state:,
              nk__accordion_target: "item"
            }
          }
        )
      ) do
        button(
          **slot_attributes(
            :trigger,
            attributes: {
              id: trigger_id(item),
              type: "button",
              disabled: item.disabled,
              aria: {
                controls: content_id(item),
                expanded: item.expanded
              },
              data: {
                action: "click->nk--accordion#toggle",
                nk__accordion_target: "trigger"
              }
            }
          )
        ) do
          span(**slot_attributes(:label)) { item.title }
          chevron
        end

        div(
          **slot_attributes(
            :content,
            attributes: {
              id: content_id(item),
              role: "region",
              hidden: item.expanded ? nil : true,
              aria: {
                hidden: !item.expanded,
                labelledby: trigger_id(item)
              },
              data: {
                state:,
                nk__accordion_target: "content"
              }
            }
          )
        ) do
          render(item.content)
        end
      end
    end

    def chevron
      svg(
        **slot_attributes(
          :icon,
          attributes: {
            viewbox: "0 0 16 16",
            width: 16,
            height: 16,
            fill: "none",
            stroke: "currentColor",
            stroke_width: 1.5,
            stroke_linecap: "round",
            stroke_linejoin: "round",
            focusable: "false",
            aria: { hidden: true }
          }
        )
      ) do |svg|
        svg.path(d: "m4 6 4 4 4-4")
      end
    end

    def trigger_id(item)
      "#{identifier}-#{item.key}-trigger"
    end

    def content_id(item)
      "#{identifier}-#{item.key}-content"
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Accordion items must be declared inside the render block"
    end

    def validate_title!(title)
      return title if title.is_a?(String) && title.present?

      raise ArgumentError, "Accordion item title must be a non-blank String"
    end

    def validate_boolean!(name, value)
      return value if value == true || value == false

      raise ArgumentError, "Accordion #{name} must be true or false"
    end

    def component_id(value)
      return value if value.is_a?(String) && value.present? && !value.match?(/\s/)

      raise ArgumentError, "Accordion id must be a non-blank String without whitespace"
    end
  end
end
