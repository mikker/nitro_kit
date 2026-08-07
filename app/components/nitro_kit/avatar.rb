# frozen_string_literal: true

module NitroKit
  class Avatar < Component
    SIZES = %i[xs sm md lg].freeze

    def initialize(
      src: nil,
      alt: "",
      fallback: nil,
      size: :md,
      decorative: false,
      loading: "lazy",
      decoding: "async",
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      raise ArgumentError, "alt must be a String" unless alt.is_a?(String)
      @decorative = validate_boolean!(:decorative, decorative)
      unless fallback.nil? || fallback.is_a?(String)
        raise ArgumentError, "fallback must be a String or nil"
      end

      @src = src
      @alt = alt
      if src? && alt.empty? && !@decorative
        raise ArgumentError, "Avatar images require alt: text unless decorative: true"
      end
      @fallback = fallback || initials_for(alt)
      @size = validate_choice!(:size, size, SIZES)
      root_aria = fallback_aria(aria)

      super(
        component: :avatar,
        attributes: {
          id:,
          role: !src? && !alt.empty? ? "img" : nil,
          data: { controller: src? ? "nk--avatar" : nil }.compact
        },
        html:,
        aria: root_aria,
        data:,
        size:,
        desperately_need_a_class:
      )

      @image_attributes = {
        alt:,
        loading:,
        decoding:
      }
    end

    attr_reader :src, :alt, :fallback, :size, :decorative

    def view_template
      span(**root_attributes) do
        span(
          **slot_attributes(
            :fallback,
            attributes: src? ? { data: { nk__avatar_target: "fallback" } } : {},
            aria: { hidden: (src? || !alt.empty?) ? true : nil }
          )
        ) { fallback }

        if src?
          img(
            **slot_attributes(
              :image,
              attributes: @image_attributes.merge(
                src:,
                data: {
                  nk__avatar_target: "image",
                  action: "error->nk--avatar#failed"
                }
              )
            )
          )
        end
      end
    end

    private

    def src?
      !src.nil? && (!src.respond_to?(:empty?) || !src.empty?)
    end

    def fallback_aria(aria)
      return aria if src? || alt.empty?
      raise ArgumentError, "aria must be a Hash" unless aria.is_a?(Hash)

      label_key = aria.keys.find { |key| key.to_s.downcase.tr("_", "-") == "label" }
      label_key ? aria : { label: alt }.merge(aria)
    end

    def initials_for(name)
      words = name.strip.split
      return "?" if words.empty?

      initials = if words.one?
        words.first[0, 2]
      else
        [ words.first[0], words.last[0] ].join
      end

      initials.upcase
    end
  end
end
