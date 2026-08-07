# frozen_string_literal: true

module NitroKit
  class Tabs < Component
    ORIENTATIONS = %i[horizontal vertical].freeze
    ACTIVATIONS = %i[automatic manual].freeze
    Tab = ::Data.define(:key, :label, :disabled, :content)

    def initialize(
      default: nil,
      id:,
      label: I18n.t("nitro_kit.tabs.label"),
      orientation: :horizontal,
      activation: :automatic,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = validate_id!("Tabs id", id)
      @default = default.nil? ? nil : normalize_identity(default, name: "default tab key")
      @label = validate_label!(label)
      @orientation = validate_choice!(:orientation, orientation, ORIENTATIONS)
      @activation = validate_choice!(:activation, activation, ACTIVATIONS)
      @tabs = []

      super(
        component: :tabs,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--tabs",
            orientation: @orientation,
            activation: @activation,
            nk__tabs_active_value: @default || "",
            nk__tabs_orientation_value: @orientation,
            nk__tabs_activation_value: @activation
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :default, :label, :orientation, :activation

    def view_template(&block)
      collect_tabs(&block)
      active_key = resolve_active_key

      div(**root_attributes_for(active_key)) do
        render_tablist(active_key)
        @tabs.each { |tab| render_panel(tab, active_key:) }
      end
    end

    def tab(key, label, disabled: false, &content)
      ensure_collecting!

      key = normalize_identity(key, name: "tab key")
      label = validate_label!(label)
      disabled = validate_boolean!(:disabled, disabled)
      raise ArgumentError, "Tab #{key.inspect} requires panel content" unless content
      raise ArgumentError, "Duplicate tab key #{key.inspect}" if find_tab(key)

      @tabs << Tab.new(key:, label:, disabled:, content:)
      nil
    end

    private

    def collect_tabs
      raise ArgumentError, "Tabs requires a tab declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "Tabs requires at least one tab" if @tabs.empty?
    ensure
      @collecting = false
    end

    def render_tablist(active_key)
      div(
        **slot_attributes(
          :list,
          attributes: {
            role: "tablist",
            aria: {
              label:,
              orientation:
            }
          }
        )
      ) do
        @tabs.each { |tab| render_tab(tab, active_key:) }
      end
    end

    def render_tab(tab, active_key:)
      active = tab.key == active_key

      button(
        **slot_attributes(
          :tab,
          attributes: {
            id: tab_id(tab),
            type: "button",
            role: "tab",
            disabled: tab.disabled,
            tabindex: tab.disabled ? -1 : 0,
            aria: {
              controls: panel_id(tab),
              selected: active
            },
            data: {
              key: tab.key,
              state: active ? "active" : "inactive",
              action: "click->nk--tabs#select keydown->nk--tabs#navigate",
              nk__tabs_target: "tab"
            }
          }
        )
      ) { tab.label }
    end

    def render_panel(tab, active_key:)
      active = tab.key == active_key

      div(
        **slot_attributes(
          :panel,
          attributes: {
            id: panel_id(tab),
            role: "tabpanel",
            aria: {
              labelledby: tab_id(tab)
            },
            data: {
              key: tab.key,
              state: active ? "active" : "inactive",
              nk__tabs_target: "panel"
            }
          }
        )
      ) do
        render(tab.content)
      end
    end

    def resolve_active_key
      enabled_tabs = @tabs.reject(&:disabled)
      raise ArgumentError, "Tabs requires at least one enabled tab" if enabled_tabs.empty?

      return enabled_tabs.first.key unless default

      selected = find_tab(default)
      raise ArgumentError, "Default tab key #{default.inspect} is not declared" unless selected
      raise ArgumentError, "Default tab #{default.inspect} cannot be disabled" if selected.disabled

      selected.key
    end

    def root_attributes_for(active_key)
      attributes = root_attributes

      attributes.merge(
        data: attributes.fetch(:data).merge(nk__tabs_active_value: active_key)
      )
    end

    def tab_id(tab)
      "#{identifier}-#{tab.key}-tab"
    end

    def panel_id(tab)
      "#{identifier}-#{tab.key}-panel"
    end

    def find_tab(key)
      @tabs.find { |tab| tab.key == key }
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "Tabs must be declared inside the render block"
    end

    def validate_label!(value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Tabs labels must be non-blank Strings"
    end
  end
end
