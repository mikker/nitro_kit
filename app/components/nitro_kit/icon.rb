# frozen_string_literal: true

require "lucide-rails"

module NitroKit
  class Icon < Component
    SIZES = %i[xs sm md lg xl].freeze
    STROKE_WIDTHS = (0.5..4).freeze

    def initialize(
      name,
      size: :md,
      label: nil,
      stroke_width: 1.5,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @name = name.to_s.tr("_", "-")
      @size = validate_choice!(:size, size, SIZES)
      @label = label
      if !label.nil? && (!label.is_a?(String) || label.strip.empty?)
        raise ArgumentError, "Icon label: must be a non-blank String"
      end
      @stroke_width = validate_stroke_width!(stroke_width)
      @icon = LucideRails::IconProvider.icon(@name)

      raise ArgumentError, "Unknown icon #{@name.inspect}" unless @icon

      icon_aria = label ? { label:, hidden: false } : { hidden: true }

      super(
        component: :icon,
        attributes: {
          id:,
          width: 24,
          height: 24,
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: @stroke_width,
          stroke_linecap: "round",
          stroke_linejoin: "round",
          focusable: false,
          role: label && "img",
          aria: icon_aria
        }.compact,
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :name, :size, :label, :stroke_width

    def view_template
      svg(**root_attributes) { raw safe(@icon) }
    end

    private

    def validate_stroke_width!(value)
      return value if value.is_a?(Numeric) && !value.is_a?(Complex) && STROKE_WIDTHS.cover?(value)

      raise ArgumentError,
        "Icon stroke_width: must be a number between #{STROKE_WIDTHS.begin} and #{STROKE_WIDTHS.end}; " \
        "received #{value.inspect}"
    end
  end
end
