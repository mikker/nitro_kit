# frozen_string_literal: true

module NitroKit
  class StatGrid < Component
    Stat = Data.define(:key, :label, :value, :detail)

    def initialize(
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @stats = []

      super(
        component: :stat_grid,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      yield self if block_given?
      raise ArgumentError, "StatGrid requires at least one stat" if @stats.empty?

      div(**root_attributes) do
        render_in_slot(Grid.new(cols: "1 sm:2 lg:3"), :grid) do
          @stats.each { |stat| render_stat(stat) }
        end
      end
    end

    def stat(key:, label:, value:, detail: nil)
      key = normalize_identity(key, name: "stat key")
      raise ArgumentError, "StatGrid stat keys must be unique: #{key.inspect}" if @stats.any? { |stat| stat.key == key }

      @stats << Stat.new(
        key:,
        label: validate_text!(:label, label),
        value: validate_text!(:value, value),
        detail: validate_optional_text!(:detail, detail)
      )
      nil
    end

    private

    def render_stat(stat)
      dl(**slot_attributes(:stat, attributes: { data: { key: stat.key } })) do
        dt(**slot_attributes(:label)) { plain(stat.label) }
        dd(**slot_attributes(:value)) { plain(stat.value) }
        dd(**slot_attributes(:detail)) { plain(stat.detail) } if stat.detail
      end
    end

    def validate_text!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "#{name} must be a non-blank String"
    end

    def validate_optional_text!(name, value)
      return if value.nil?

      validate_text!(name, value)
    end
  end
end
