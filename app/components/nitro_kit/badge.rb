# frozen_string_literal: true

module NitroKit
  class Badge < Component
    VARIANTS = %i[default outline].freeze
    SIZES = %i[sm md].freeze
    COLORS = %i[neutral info success warning danger].freeze

    def initialize(
      text = nil,
      variant: :default,
      size: :md,
      color: :neutral,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil,
      &block
    )
      @text = text
      @content = block
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
      content = block || @content
      if !content && (text.nil? || text.to_s.strip.empty?)
        raise ArgumentError, "Badge label content is required"
      end

      span(**root_attributes) do
        span(**slot_attributes(:label)) do
          if content
            text_or_block(nil, &content)
          else
            plain(text.to_s)
          end
        end
      end
    end
  end
end
