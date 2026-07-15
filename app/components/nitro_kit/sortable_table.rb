# frozen_string_literal: true

module NitroKit
  class SortableTable < Component
    DIRECTIONS = %i[asc desc].freeze

    def initialize(
      current: nil,
      direction: nil,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @current = normalize_key(current, name: "current", optional: true)
      @direction = normalize_direction(direction)
      @sortable_keys = []
      @table = Table.new

      validate_sort_state!

      super(
        component: :sortable_table,
        attributes: {
          id:,
          data: { current: @current, direction: @direction }.compact
        }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :current, :direction

    def view_template
      div(**root_attributes) do
        render_in_slot(@table, :table) do
          yield self if block_given?
        end
        validate_headers!
      end
    end

    def caption(...) = @table.caption(...)
    def thead(...) = @table.thead(...)
    def tbody(...) = @table.tbody(...)
    def tr(...) = @table.tr(...)
    def th(...) = @table.th(...)
    def td(...) = @table.td(...)

    def sortable_th(key, label = nil, href:, align: :left)
      key = normalize_key(key, name: "sortable header key")
      label = key.humanize if label.nil?
      validate_label!(label)
      validate_href!(href)
      raise ArgumentError, "SortableTable header keys must be unique" if @sortable_keys.include?(key)

      @sortable_keys << key
      active = current == key

      @table.th(
        align:,
        aria: active ? { sort: aria_sort } : {},
        data: { sort_key: key }
      ) do
        a(**slot_attributes(:link, attributes: { href: })) do
          plain(label)
          sort_indicator if active
        end
      end
    end

    private

    def sort_indicator
      span(**slot_attributes(:indicator, aria: { hidden: true })) do
        direction == :asc ? "↑" : "↓"
      end
    end

    def aria_sort
      direction == :asc ? "ascending" : "descending"
    end

    def normalize_key(value, name:, optional: false)
      return if optional && value.nil?

      normalized = value.to_s.strip if value.is_a?(Symbol) || value.is_a?(String)
      return normalized if normalized.present?

      raise ArgumentError, "SortableTable #{name} must be a Symbol or non-blank String"
    end

    def normalize_direction(value)
      return if value.nil?

      normalized = value.respond_to?(:to_sym) ? value.to_sym : value
      validate_choice!(:direction, normalized, DIRECTIONS)
    end

    def validate_sort_state!
      return if current.nil? == direction.nil?

      raise ArgumentError, "SortableTable current and direction must both be set or both be nil"
    end

    def validate_headers!
      raise ArgumentError, "SortableTable requires at least one sortable header" if @sortable_keys.empty?
      return if current.nil? || @sortable_keys.include?(current)

      raise ArgumentError, "SortableTable current key #{current.inspect} must match a sortable header"
    end

    def validate_label!(label)
      return if label.is_a?(String) && !label.strip.empty?

      raise ArgumentError, "SortableTable header label must be a non-blank String"
    end

    def validate_href!(href)
      return if href.is_a?(String) && !href.strip.empty?

      raise ArgumentError, "SortableTable header href must be a non-blank String"
    end
  end
end
