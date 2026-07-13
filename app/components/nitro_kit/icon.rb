# frozen_string_literal: true

require "lucide-rails"

module NitroKit
  class Icon < Component
    SIZES = %i[xs sm md lg].freeze

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
          stroke_width:,
          stroke_linecap: "round",
          stroke_linejoin: "round",
          focusable: false,
          role: label && "img"
        }.compact,
        html:,
        aria: aria.merge(icon_aria),
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :name, :size, :label

    def view_template
      svg(**root_attributes) { raw safe(@icon) }
    end
  end
end
