# frozen_string_literal: true

module NitroKit
  class StatGrid < Component
    DEFAULT_COLUMNS = "1 sm:2 lg:3"
    Stat = Data.define(:key, :label, :value, :detail)

    def initialize(
      cols: DEFAULT_COLUMNS,
      gap: 4,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @stats = []
      @grid = Grid.new(cols:, gap:)

      super(
        component: :stat_grid,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template(&block)
      collect_declarations(&block)
      raise ArgumentError, "StatGrid requires at least one stat" if @stats.empty?

      div(**root_attributes) do
        render_in_slot(@grid, :grid) do
          html_dl(**slot_attributes(:list)) do
            @stats.each { |stat| render_stat(stat) }
          end
        end
      end
    end

    def stat(key:, label:, value:, detail: nil)
      ensure_collecting!
      key = normalize_identity(key, name: "stat key")
      raise ArgumentError, "StatGrid stat keys must be unique: #{key.inspect}" if @stats.any? { |stat| stat.key == key }

      @stats << Stat.new(
        key:,
        label: present_text!(:label, label),
        value: present_text!(:value, value),
        detail: detail.nil? ? nil : present_text!(:detail, detail)
      )
      nil
    end

    alias :html_dl :dl

    private

    def collect_declarations
      return unless block_given?

      @collecting = true
      yield(self)
    ensure
      @collecting = false
    end

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "StatGrid stats must be declared inside the render block"
    end

    def render_stat(stat)
      div(**slot_attributes(:stat, attributes: { data: { key: stat.key } })) do
        dt(**slot_attributes(:label)) { plain(stat.label) }
        dd(**slot_attributes(:value)) { plain(stat.value) }
        dd(**slot_attributes(:detail)) { plain(stat.detail) } if stat.detail
      end
    end

    def present_text!(name, value)
      text = value.to_s
      raise ArgumentError, "StatGrid #{name} must not be blank" if text.strip.empty?

      text
    end
  end
end
