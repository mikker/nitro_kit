# frozen_string_literal: true

module NitroKit
  class Badge < Component
    VARIANTS = %i[default outline].freeze
    SIZES = %i[sm md].freeze
    COLORS = %i[
      zinc red orange amber yellow lime green emerald teal cyan sky blue indigo
      violet purple fuchsia pink rose neutral info success warning danger
    ].freeze

    def initialize(
      text = nil,
      variant: :default,
      size: :md,
      color: :zinc,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      if !text.nil? && text.to_s.strip.empty?
        raise ArgumentError, "Badge label content is required"
      end

      @text = text
      @variant = validate_choice!(:variant, variant, VARIANTS)
      @size = validate_choice!(:size, size, SIZES)
      @color = validate_choice!(:color, color, COLORS)

      super(
        component: :badge,
        attributes: {
          id:,
          data: { color: }
        },
        html:,
        aria:,
        data:,
        variant:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :text, :variant, :size, :color

    def view_template(&block)
      if block && !text.nil?
        raise ArgumentError, "Badge accepts label text or block content, not both"
      end
      if !block && text.nil?
        raise ArgumentError, "Badge label content is required"
      end

      span(**root_attributes) do
        span(**slot_attributes(:label)) do
          block ? text_or_block(nil, &block) : plain(text.to_s)
        end
      end
    end
  end
end
