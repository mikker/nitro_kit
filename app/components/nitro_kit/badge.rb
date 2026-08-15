# frozen_string_literal: true

module NitroKit
  class Badge < Component
    VARIANTS = %i[default outline].freeze
    SIZES = %i[xs sm md].freeze
    # Two axes on one option, both public and both themeable.
    #
    # The semantic families follow the `--nk-palette-{family}` tint roles, so
    # they move with an application's brand: retheme `--nk-palette-danger` and
    # every `danger` badge follows. The decorative hues follow the
    # `--nk-palette-{hue}` roles and stay the color they name, for categorical
    # labelling where meaning is not the point.
    SEMANTIC_COLORS = %i[neutral info success warning danger].freeze
    PALETTE_COLORS = %i[
      zinc red orange amber yellow lime green emerald teal cyan sky blue indigo
      violet purple fuchsia pink rose
    ].freeze
    COLORS = (PALETTE_COLORS + SEMANTIC_COLORS).freeze

    def initialize(
      text = nil,
      variant: :default,
      size: :md,
      color: :neutral,
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
