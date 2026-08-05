# frozen_string_literal: true

module NitroKit
  class ProgressiveImage < Component
    include Phlex::Rails::Helpers::Routes

    SIZES = %i[sm md lg].freeze
    PIXELS = { sm: 320, md: 720, lg: 1_440 }.freeze
    PLACEHOLDER_PIXELS = 48

    def initialize(
      attachment:,
      alt: nil,
      size: :md,
      decorative: false,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @attachment = validate_attachment!(attachment)
      @size = validate_choice!(:size, size, SIZES)
      @decorative = validate_boolean!(:decorative, decorative)
      @attached = attachment&.attached? || false
      @alt = validate_alt!(alt)

      validate_attached_contract! if @attached

      super(
        component: :progressive_image,
        attributes: {
          id:,
          aria: { busy: @attached ? true : nil },
          data: {
            state: @attached ? "loading" : "empty",
            controller: @attached ? "nk--progressive-image" : nil,
            action: @attached ? "turbo:before-cache@document->nk--progressive-image#prepareForCache" : nil
          }.compact
        },
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    attr_reader :attachment, :alt, :size, :decorative

    def view_template
      div(**root_attributes) do
        if @attached
          render_placeholder
          render_image
        end

        render_fallback
      end
    end

    private

    def render_placeholder
      img(
        **slot_attributes(
          :placeholder,
          attributes: image_dimensions.merge(
            src: variant_url(PLACEHOLDER_PIXELS),
            alt: "",
            loading: "eager",
            decoding: "async"
          ),
          aria: { hidden: true }
        )
      )
    end

    def render_image
      pixels = PIXELS.fetch(size)
      image_url = variant_url(pixels)

      img(
        **slot_attributes(
          :image,
          attributes: image_dimensions.merge(
            src: image_url,
            srcset: "#{image_url} 1x, #{variant_url(pixels * 2)} 2x",
            alt:,
            loading: "lazy",
            decoding: "async",
            data: { nk__progressive_image_target: "image" }
          )
        )
      )
    end

    def render_fallback
      visible = !@attached
      accessible = !decorative

      span(
        **slot_attributes(
          :fallback,
          attributes: {
            hidden: visible ? nil : true,
            # Only an attached image can change state after render, so only
            # that fallback is a live region.
            role: (accessible && @attached) ? "status" : nil
          },
          aria: {
            hidden: accessible ? nil : true
          },
          data: @attached ? { nk__progressive_image_target: "fallback" } : {}
        )
      ) { fallback_text }
    end

    def fallback_text
      alt.strip.empty? ? I18n.t("nitro_kit.progressive_image.unavailable") : alt
    end

    def variant_url(pixels)
      representation = attachment.variant(resize_to_limit: [ pixels, pixels ])
      return representation if representation.is_a?(String)

      url_for(representation)
    end

    def image_dimensions
      blob = attachment.blob
      return {} if blob.respond_to?(:analyzed?) && !blob.analyzed?

      metadata = blob.metadata
      return {} unless metadata.is_a?(Hash)

      width = metadata["width"] || metadata[:width]
      height = metadata["height"] || metadata[:height]
      return {} unless positive_dimension?(width) && positive_dimension?(height)

      { width:, height: }
    end

    def positive_dimension?(value)
      value.is_a?(Numeric) && value.positive?
    end

    def validate_attachment!(value)
      return value if value.nil? || value.respond_to?(:attached?)

      raise ArgumentError, "attachment must be nil or an Active Storage attachment"
    end

    def validate_attached_contract!
      missing = %i[variant blob].reject { |method| attachment.respond_to?(method) }
      unless missing.empty?
        raise ArgumentError, "attached image must expose #{missing.join(' and ')}"
      end

      blob = attachment.blob
      unless blob.respond_to?(:image?) && blob.image? && blob.respond_to?(:variable?) && blob.variable?
        raise ArgumentError, "attached image must have an image blob that supports variants"
      end
    end

    def validate_alt!(value)
      unless value.nil? || value.is_a?(String)
        raise ArgumentError, "alt must be a String or nil"
      end
      return "" if decorative

      if value.nil?
        raise ArgumentError, "alt: is required unless decorative: true"
      end
      if @attached && value.strip.empty?
        raise ArgumentError, "attached non-decorative images require non-blank alt text"
      end

      value
    end
  end
end
